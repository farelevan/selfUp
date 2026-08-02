# SelfUp iOS MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an offline-first iOS 17+ SelfUp app that tracks daily habits, cash flow, and tasks, with gamified progress, charts, and a narrow Siri/Shortcuts integration.

**Architecture:** A SwiftUI app uses SwiftData for persistence and a small domain layer for calculations and validation. Feature views read records through `@Query` and call focused services for completions and progress; a root router owns selected tab and deep links. System-facing App Intents delegate to the same services rather than duplicating rules.

**Tech Stack:** Swift 5.9, SwiftUI, SwiftData, Swift Charts, App Intents, XCTest, iOS 17+.

## Global Constraints

- iOS deployment target: 17.0.
- No accounts, network traffic, analytics, or cloud synchronization.
- All user records reside in a local SwiftData store.
- UI uses semantic SwiftUI colors and SF Symbols, not hard-coded brand-color-only meaning.
- Financial amounts use `Decimal`; currency is configurable and defaults to `IDR`.
- XP can be granted only once for a habit completion or task completion.
- Import validates a full JSON payload before replacing stored records.
- App Intents expose only Log Expense, Complete Habit, and Open Section.

---

## File map

- `SelfUp/SelfUpApp.swift`: SwiftData container, root route handling, App Intent routing.
- `SelfUp/Models/*.swift`: SwiftData models and value types.
- `SelfUp/Services/*.swift`: pure progress calculations, record mutation, backup import/export.
- `SelfUp/Features/{Today,Habits,Money,Tasks,Insights,Settings}/*.swift`: feature-specific SwiftUI screens and editors.
- `SelfUp/AppIntents/*.swift`: App Intents, habit entity/query, shortcut provider.
- `SelfUpTests/*.swift`: deterministic XCTest coverage for services and validation.
- `SelfUp.xcodeproj`: native Xcode project containing app and test targets.

### Task 1: Bootstrap the native project and domain types

**Files:**
- Create: `SelfUp.xcodeproj`, `SelfUp/SelfUpApp.swift`, `SelfUp/Models/Habit.swift`, `SelfUp/Models/HabitCompletion.swift`, `SelfUp/Models/Transaction.swift`, `SelfUp/Models/TaskItem.swift`, `SelfUp/Models/AppDestination.swift`, `SelfUpTests/ModelDefaultsTests.swift`.

**Interfaces:**
- Produces `Habit`, `HabitCompletion`, `Transaction`, `TaskItem`, and `AppDestination` used by all subsequent tasks.

- [ ] **Step 1: Write the failing model-default test**

```swift
func testNewHabitStartsWithNoCompletionsAndDefaultXP() {
    let habit = Habit(title: "Drink water")
    XCTAssertEqual(habit.xpReward, 10)
    XCTAssertTrue(habit.completions.isEmpty)
    XCTAssertFalse(habit.isArchived)
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -scheme SelfUp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SelfUpTests/ModelDefaultsTests/testNewHabitStartsWithNoCompletionsAndDefaultXP`

Expected: failure because `Habit` does not exist.

- [ ] **Step 3: Implement the smallest SwiftData model set**

```swift
@Model final class Habit {
    var id: UUID; var title: String; var symbol: String; var tintName: String
    var xpReward: Int; var isArchived: Bool; var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []
    init(title: String, symbol: String = "checkmark.circle.fill", xpReward: Int = 10) { /* assign fields */ }
}

enum AppDestination: String, CaseIterable, AppEnum { case today, habits, money, tasks }
```

Create analogous models: `HabitCompletion(id, date, habit)`, `Transaction(id, amount: Decimal, type, category, note, date)`, and `TaskItem(id, title, dueDate, priority, completedAt, xpReward)`.

- [ ] **Step 4: Run the focused test, then all tests**

Run: `xcodebuild test -scheme SelfUp -destination 'platform=iOS Simulator,name=iPhone 16'`

Expected: passing test suite.

- [ ] **Step 5: Commit**

Run: `git add SelfUp SelfUpTests SelfUp.xcodeproj && git commit -m "feat: bootstrap SelfUp domain models"`

### Task 2: Implement progress and money calculation services

**Files:**
- Create: `SelfUp/Services/ProgressService.swift`, `SelfUp/Services/MoneySummaryService.swift`, `SelfUpTests/ProgressServiceTests.swift`, `SelfUpTests/MoneySummaryServiceTests.swift`.

**Interfaces:**
- Consumes: the models from Task 1.
- Produces `ProgressSnapshot`, `MoneySummary`, `isCompleted(_:on:)`, `streak(for:through:)`, and `lifeScore(habits:tasks:transactions:on:)` for feature views.

- [ ] **Step 1: Write the failing streak and net-flow tests**

```swift
func testStreakCountsConsecutiveCompletionDaysEndingToday() {
    let dates = [today, calendar.date(byAdding: .day, value: -1, to: today)!]
    XCTAssertEqual(ProgressService.streak(completionDates: dates, through: today), 2)
}

func testMoneySummarySubtractsExpensesFromIncome() {
    let summary = MoneySummaryService.summary(for: [income(100), expense(35)])
    XCTAssertEqual(summary.net, Decimal(65))
}
```

- [ ] **Step 2: Run tests and verify expected failures**

Run: `xcodebuild test -scheme SelfUp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SelfUpTests/ProgressServiceTests -only-testing:SelfUpTests/MoneySummaryServiceTests`

Expected: failure because the services are missing.

- [ ] **Step 3: Implement pure, calendar-injected calculations**

```swift
struct MoneySummary { let income: Decimal; let expenses: Decimal; var net: Decimal { income - expenses } }
enum MoneySummaryService {
    static func summary(for transactions: [Transaction]) -> MoneySummary { /* reduce by type */ }
}
enum ProgressService {
    static func streak(completionDates: [Date], through day: Date, calendar: Calendar = .current) -> Int { /* normalized-day loop */ }
}
```

Define Life Score as: 50 points for the fraction of active habits completed today, 40 for the fraction of tasks due today completed, and 10 when any transaction was logged today; clamp to 0...100.

- [ ] **Step 4: Run all unit tests**

Run: `xcodebuild test -scheme SelfUp -destination 'platform=iOS Simulator,name=iPhone 16'`

Expected: all progress and money tests pass.

- [ ] **Step 5: Commit**

Run: `git add SelfUp/Services SelfUpTests && git commit -m "feat: add progress and cash-flow calculations"`

### Task 3: Build data mutations and the Habits/Tasks experience

**Files:**
- Create: `SelfUp/Services/TrackingService.swift`, `SelfUp/Features/Habits/HabitsView.swift`, `SelfUp/Features/Habits/HabitEditorView.swift`, `SelfUp/Features/Tasks/TasksView.swift`, `SelfUp/Features/Tasks/TaskEditorView.swift`, `SelfUpTests/TrackingServiceTests.swift`.

**Interfaces:**
- Consumes: Task 1 models and `ProgressService`.
- Produces: `toggleHabit(_:on:context:)` and `toggleTask(_:on:context:)`; both return `Bool` indicating whether XP should change.

- [ ] **Step 1: Write failing idempotency tests**

```swift
func testCompletingSameHabitTwiceOnOneDayCreatesOneCompletion() throws {
    XCTAssertTrue(try service.toggleHabit(habit, on: today, context: context))
    XCTAssertFalse(try service.toggleHabit(habit, on: today, context: context))
    XCTAssertEqual(habit.completions.count, 1)
}
```

- [ ] **Step 2: Run and verify the failure**

Run: `xcodebuild test -scheme SelfUp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SelfUpTests/TrackingServiceTests`

Expected: failure because `TrackingService` is missing.

- [ ] **Step 3: Implement mutation service and focused UI**

```swift
@MainActor struct TrackingService {
    func toggleHabit(_ habit: Habit, on date: Date, context: ModelContext) throws -> Bool { /* create or remove today's completion */ }
    func toggleTask(_ task: TaskItem, on date: Date, context: ModelContext) throws -> Bool { /* set or clear completedAt */ }
}
```

Build each list with an empty state, add button, swipe archive/delete as appropriate, accessible labels, and a sheet editor that rejects a blank title before saving.

- [ ] **Step 4: Run tests and manual simulator smoke test**

Run: `xcodebuild test -scheme SelfUp -destination 'platform=iOS Simulator,name=iPhone 16'`

Expected: all tests pass; completing a row updates its visual state once.

- [ ] **Step 5: Commit**

Run: `git add SelfUp/Services/TrackingService.swift SelfUp/Features/Habits SelfUp/Features/Tasks SelfUpTests && git commit -m "feat: add habit and task tracking"`

### Task 4: Build money recording, summary, and charts

**Files:**
- Create: `SelfUp/Features/Money/MoneyView.swift`, `SelfUp/Features/Money/TransactionEditorView.swift`, `SelfUp/Features/Money/MoneyChartView.swift`, `SelfUpTests/TransactionValidationTests.swift`.

**Interfaces:**
- Consumes: `Transaction` and `MoneySummaryService`.
- Produces: validated `TransactionDraft.makeTransaction()` and chart-ready monthly/categorical aggregates.

- [ ] **Step 1: Write the failing amount validation test**

```swift
func testTransactionDraftRejectsZeroAmount() {
    XCTAssertThrowsError(try TransactionDraft(amountText: "0", type: .expense, category: "Food").makeTransaction())
}
```

- [ ] **Step 2: Run and verify the failure**

Run: `xcodebuild test -scheme SelfUp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SelfUpTests/TransactionValidationTests`

Expected: failure because `TransactionDraft` is missing.

- [ ] **Step 3: Implement validated recording and visual summary**

```swift
struct TransactionDraft {
    func makeTransaction() throws -> Transaction {
        guard let amount = Decimal(string: amountText), amount > 0 else { throw ValidationError.invalidAmount }
        return Transaction(amount: amount, type: type, category: category, note: note, date: date)
    }
}
```

Use a segmented income/expense control, predefined editable categories, transaction list, monthly income/expense/net cards, and `Chart` views for monthly flow and expense-category share.

- [ ] **Step 4: Run tests and inspect the Money tab in Simulator**

Run: `xcodebuild test -scheme SelfUp -destination 'platform=iOS Simulator,name=iPhone 16'`

Expected: all tests pass; invalid amount gives inline feedback and does not insert a record.

- [ ] **Step 5: Commit**

Run: `git add SelfUp/Features/Money SelfUpTests && git commit -m "feat: add local cash-flow tracking"`

### Task 5: Compose dashboard, Insights, data backup, and settings

**Files:**
- Create: `SelfUp/Features/Today/TodayView.swift`, `SelfUp/Features/Insights/InsightsView.swift`, `SelfUp/Features/Settings/SettingsView.swift`, `SelfUp/Services/BackupService.swift`, `SelfUpTests/BackupServiceTests.swift`.
- Modify: `SelfUp/SelfUpApp.swift`.

**Interfaces:**
- Consumes: all models and services.
- Produces: dashboard snapshot, seven-day charts, `BackupPayload`, `exportData()`, and `validateImport(_:)`.

- [ ] **Step 1: Write a failing import validation test**

```swift
func testImportRejectsPayloadWithTransactionMissingCategory() throws {
    let data = try JSONEncoder().encode(BackupPayload.invalidTransaction())
    XCTAssertThrowsError(try BackupService.validateImport(data))
}
```

- [ ] **Step 2: Run and verify the failure**

Run: `xcodebuild test -scheme SelfUp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SelfUpTests/BackupServiceTests`

Expected: failure because `BackupService` is missing.

- [ ] **Step 3: Implement dashboard, insights, and guarded backup**

```swift
struct BackupPayload: Codable { let habits: [HabitBackup]; let transactions: [TransactionBackup]; let tasks: [TaskBackup] }
enum BackupService {
    static func validateImport(_ data: Data) throws -> BackupPayload { /* decode, reject blank titles/categories or non-positive amounts */ }
}
```

Compose `TabView` with Today, Habits, Money, Tasks, Insights. Add a settings sheet for currency, `fileExporter`, `fileImporter`, and a destructive confirmation before applying a validated import. The Today and Insights screens use `Chart` and show helpful empty states.

- [ ] **Step 4: Run test suite and backup round-trip check**

Run: `xcodebuild test -scheme SelfUp -destination 'platform=iOS Simulator,name=iPhone 16'`

Expected: all tests pass; invalid import leaves existing data untouched.

- [ ] **Step 5: Commit**

Run: `git add SelfUp SelfUpTests && git commit -m "feat: add dashboard insights and local backup"`

### Task 6: Add App Intents, shortcuts, and simulator proof

**Files:**
- Create: `SelfUp/AppIntents/LogExpenseIntent.swift`, `SelfUp/AppIntents/CompleteHabitIntent.swift`, `SelfUp/AppIntents/OpenSectionIntent.swift`, `SelfUp/AppIntents/SelfUpShortcuts.swift`, `SelfUpTests/AppIntentRoutingTests.swift`.
- Modify: `SelfUp/SelfUpApp.swift`, `SelfUp/Services/TrackingService.swift`.

**Interfaces:**
- Consumes: `TrackingService`, `Transaction`, `Habit`, and `AppDestination`.
- Produces: system-discoverable Log Expense, Complete Habit, and Open Section commands, with a single `AppRouter.navigate(to:)` handoff.

- [ ] **Step 1: Write failing route and inline-expense tests**

```swift
func testOpenSectionIntentRoutesToMoney() {
    let router = AppRouter()
    router.navigate(to: .money)
    XCTAssertEqual(router.destination, .money)
}
```

- [ ] **Step 2: Run and verify expected failure**

Run: `xcodebuild test -scheme SelfUp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SelfUpTests/AppIntentRoutingTests`

Expected: failure because `AppRouter` is missing.

- [ ] **Step 3: Implement a narrow App Intents layer**

```swift
struct OpenSectionIntent: AppIntent {
    static let title: LocalizedStringResource = "Open SelfUp Section"
    @Parameter(title: "Section") var destination: AppDestination
    func perform() async throws -> some IntentResult { await AppRouter.shared.navigate(to: destination); return .result() }
}
```

Implement `HabitEntity` with only stable ID and title, a simple query for active habits, a non-opening `LogExpenseIntent` and `CompleteHabitIntent`, and `AppShortcutsProvider` phrases such as “Log an expense in SelfUp”. Keep persistence/mutation rules inside existing services.

- [ ] **Step 4: Build, test, run, mirror, and capture proof**

Run: `xcodebuild test -scheme SelfUp -destination 'platform=iOS Simulator,name=iPhone 16' && xcrun simctl list devices available`

Expected: all tests pass and an available simulator UDID is printed. Launch the app on that UDID, run `serve-sim` scoped to it, open the emitted local URL in the in-app browser, and capture a screenshot with a real rendered simulator frame.

- [ ] **Step 5: Commit**

Run: `git add SelfUp SelfUpTests && git commit -m "feat: add SelfUp shortcuts and intents"`

## Plan self-review

- Spec coverage: Tasks 1–6 cover all required tabs, local persistence, scoring, charts, validation, backup, App Intents, and Simulator verification.
- Placeholder scan: no TBD/TODO items; validation rules and score calculation are explicit.
- Consistency: all screens consume the Task 1 models; Tasks 3 and 6 share `TrackingService`; all money calculations use `Decimal`.
