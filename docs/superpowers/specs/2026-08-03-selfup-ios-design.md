# SelfUp iOS — Product Design

## Goal

SelfUp is a private, offline-first iPhone app for tracking habits, personal cash flow, and tasks in one daily workspace. It encourages follow-through through simple XP, levels, streaks, and understandable progress charts.

## Scope: first release

### Dashboard

The Today dashboard shows the date, current level and XP progress, habit completion, open tasks, a short cash-flow summary, and a compact seven-day activity chart. A daily Life Score is calculated from completed habits, completed tasks, and whether the user recorded a financial activity; it is an encouragement signal, not a financial health rating.

### Habits

Users can create, edit, archive, and check off daily habits. Each habit stores a title, colour/icon, target frequency (daily for this release), XP reward, completion dates, and current streak. Completing a habit is idempotent for the current day and grants its XP once.

### Money

Users can record income and expenses with amount, category, date, optional note, and type. The Money tab shows current-month income, expenses, net flow, category breakdown, and a simple monthly trend. All values are presented in the user-selected currency.

### Tasks

Users can create, edit, complete, and delete tasks. A task includes title, optional due date, priority, completion date, and XP reward. Completing a task grants XP once; the Today dashboard emphasizes due and high-priority tasks.

### Insights

Insights shows habit consistency, task completion, monthly cash-flow, and the combined Life Score across a selectable recent range. The charts use local data only.

### Settings and data control

The app has no account and makes no network requests. Local data is stored on the device. Settings include currency, data export to a JSON file, and import with validation and an explicit overwrite confirmation. The app also seeds a small optional demo dataset on first launch.

## App structure

SwiftUI provides a `TabView` with Today, Habits, Money, Tasks, and Insights. SwiftData holds `Habit`, `HabitCompletion`, `Transaction`, and `TaskItem` records. A lightweight `ProgressService` centralizes XP, streak, and Life Score calculation so screens do not contain business rules. The app supports iOS 17 and newer.

## System actions

The first App Intents surface is deliberately small:

1. **Log expense** — captures an amount and category, saves a transaction without opening the app when input is complete.
2. **Complete habit** — marks a selected habit as complete for today; the system exposes habits as a compact display-friendly entity.
3. **Open SelfUp section** — opens the app directly on Today, Habits, Money, or Tasks using an enum destination.

An `AppShortcutsProvider` makes these actions discoverable in Siri and Shortcuts. Deep-link routing is centralized in the root app state.

## Error handling

Invalid amounts and blank titles are rejected in the editor with accessible inline messaging. Duplicate completions do not change XP. Import files are decoded and validated before any existing data is replaced. Empty states explain the next useful action.

## Verification

Build and unit tests cover scoring, streaks, flow totals, task completion idempotency, and import validation. The app is run in an iPhone Simulator and mirrored in the in-app browser; a rendered simulator frame is captured as visual proof. App Intents are built and verified to route or record the expected action.

## Non-goals

The first release excludes accounts, cloud sync, bank connections, budgeting automation, widgets, Apple Watch / Huawei Watch apps, recurring non-daily habits, notifications, and sharing.
