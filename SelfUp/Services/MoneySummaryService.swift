import Foundation

struct MoneySummary {
    let income: Decimal
    let expenses: Decimal
    var net: Decimal { income - expenses }
}

enum MoneySummaryService {
    static func summary(for transactions: [Transaction]) -> MoneySummary {
        let income = transactions.filter { $0.type == .income }.reduce(Decimal(0)) { $0 + $1.amount }
        let expenses = transactions.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        return MoneySummary(income: income, expenses: expenses)
    }
}

enum FunBudgetWarningAction: Equatable {
    case none
    case schedule(Date)
    case notifyNow
}

enum FunBudgetAttention: Equatable {
    case unconfigured
    case onTrack
    case nearlyDepleted
    case depleted
}

struct FunBudgetSnapshot: Equatable {
    let periodKey: String
    let monthInterval: DateInterval
    let warningDate: Date
    let limit: Decimal
    let spent: Decimal
    let remaining: Decimal
    let overage: Decimal
    let progress: Decimal
    let attention: FunBudgetAttention
    let warningAction: FunBudgetWarningAction

    var isConfigured: Bool { limit > 0 }
    var isWarningThresholdReached: Bool {
        limit > 0 && spent * FunBudgetService.thresholdDenominator >= limit * FunBudgetService.thresholdNumerator
    }
}

/// Pure calculations for the recurring monthly Entertainment budget.
/// Callers inject both `now` and `calendar` so month, time-zone and boundary
/// behavior remain deterministic in tests and consistent for the user.
enum FunBudgetService {
    static let category = "Entertainment"
    static let thresholdNumerator = Decimal(80)
    static let thresholdDenominator = Decimal(100)

    static func snapshot(
        for transactions: [Transaction],
        limit: Decimal,
        now: Date,
        calendar: Calendar
    ) -> FunBudgetSnapshot {
        let monthInterval = calendar.dateInterval(of: .month, for: now)
            ?? DateInterval(start: now, duration: 0)
        let warningDate = midMonthWarningDate(for: now, calendar: calendar) ?? now
        let validLimit = max(Decimal.zero, limit)

        let spent = transactions.reduce(into: Decimal.zero) { total, transaction in
            guard transaction.type == .expense,
                  transaction.amount > 0,
                  isEntertainment(transaction.category),
                  monthInterval.contains(transaction.date),
                  transaction.date <= now else { return }
            total += transaction.amount
        }

        let remaining = max(Decimal.zero, validLimit - spent)
        let overage = max(Decimal.zero, spent - validLimit)
        let progress = validLimit > 0 ? spent / validLimit : .zero
        let thresholdReached = validLimit > 0
            && spent * thresholdDenominator >= validLimit * thresholdNumerator

        let attention: FunBudgetAttention
        if validLimit == 0 {
            attention = .unconfigured
        } else if spent >= validLimit {
            attention = .depleted
        } else if thresholdReached {
            attention = .nearlyDepleted
        } else {
            attention = .onTrack
        }

        let warningAction: FunBudgetWarningAction
        if !thresholdReached {
            warningAction = .none
        } else if now < warningDate {
            warningAction = .schedule(warningDate)
        } else {
            warningAction = .notifyNow
        }

        return FunBudgetSnapshot(
            periodKey: periodKey(for: now, calendar: calendar),
            monthInterval: monthInterval,
            warningDate: warningDate,
            limit: validLimit,
            spent: spent,
            remaining: remaining,
            overage: overage,
            progress: progress,
            attention: attention,
            warningAction: warningAction
        )
    }

    static func isEntertainment(_ category: String) -> Bool {
        category
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .compare(Self.category, options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX")) == .orderedSame
    }

    static func periodKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }

    static func midMonthWarningDate(for date: Date, calendar: Calendar) -> Date? {
        var components = calendar.dateComponents([.era, .year, .month], from: date)
        components.day = 15
        components.hour = 9
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)
    }
}

/// UserDefaults-backed configuration for a recurring monthly budget. Decimal
/// values are persisted as locale-independent strings to avoid Double drift.
struct FunBudgetStore {
    private enum Key {
        static let limit = "finance.funBudget.limit.v1"
        static let notificationsEnabled = "finance.funBudget.notificationsEnabled.v1"
        static let scheduledPeriod = "finance.funBudget.scheduledPeriod.v1"
        static let scheduledDate = "finance.funBudget.scheduledDate.v1"
        static let scheduledFingerprint = "finance.funBudget.scheduledFingerprint.v1"
        static let notifiedPeriod = "finance.funBudget.notifiedPeriod.v1"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var limit: Decimal {
        get {
            guard let value = defaults.string(forKey: Key.limit),
                  let decimal = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")),
                  decimal > 0 else { return .zero }
            return decimal
        }
        nonmutating set {
            guard newValue > 0 else {
                defaults.removeObject(forKey: Key.limit)
                return
            }
            defaults.set(NSDecimalNumber(decimal: newValue).stringValue, forKey: Key.limit)
        }
    }

    var notificationsEnabled: Bool {
        get { defaults.bool(forKey: Key.notificationsEnabled) }
        nonmutating set { defaults.set(newValue, forKey: Key.notificationsEnabled) }
    }

    var scheduledPeriod: String? {
        get { defaults.string(forKey: Key.scheduledPeriod) }
        nonmutating set { defaults.set(newValue, forKey: Key.scheduledPeriod) }
    }

    var scheduledDate: Date? {
        get { defaults.object(forKey: Key.scheduledDate) as? Date }
        nonmutating set { defaults.set(newValue, forKey: Key.scheduledDate) }
    }

    var scheduledFingerprint: String? {
        get { defaults.string(forKey: Key.scheduledFingerprint) }
        nonmutating set { defaults.set(newValue, forKey: Key.scheduledFingerprint) }
    }

    var notifiedPeriod: String? {
        get { defaults.string(forKey: Key.notifiedPeriod) }
        nonmutating set { defaults.set(newValue, forKey: Key.notifiedPeriod) }
    }

    func recordScheduled(period: String, date: Date, fingerprint: String) {
        scheduledPeriod = period
        scheduledDate = date
        scheduledFingerprint = fingerprint
    }

    func clearScheduled() {
        defaults.removeObject(forKey: Key.scheduledPeriod)
        defaults.removeObject(forKey: Key.scheduledDate)
        defaults.removeObject(forKey: Key.scheduledFingerprint)
    }

    func recordNotified(period: String) {
        notifiedPeriod = period
        clearScheduled()
    }
}
