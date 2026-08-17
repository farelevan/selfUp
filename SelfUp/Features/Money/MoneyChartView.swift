import SwiftUI
import Charts

struct CategoryShare: Identifiable {
    let category: String
    let amount: Decimal
    var id: String { category }

    private static let aggregateCategory = "Other"

    static func expenseBreakdown(
        for transactions: [Transaction],
        maximumCategories: Int = 5
    ) -> [CategoryShare] {
        let grouped = Dictionary(grouping: transactions.filter { $0.type == .expense }) {
            normalizedCategory($0.category)
        }
        let shares = grouped.map { category, transactions in
            CategoryShare(
                category: category,
                amount: transactions.reduce(Decimal.zero) { $0 + $1.amount }
            )
        }
        .sorted { lhs, rhs in
            if lhs.amount == rhs.amount {
                return lhs.category.localizedCaseInsensitiveCompare(rhs.category) == .orderedAscending
            }
            return lhs.amount > rhs.amount
        }

        let categoryLimit = Swift.max(maximumCategories, 1)
        guard shares.count > categoryLimit else { return shares }

        let topCategories = Array(
            shares
                .filter { $0.category != aggregateCategory }
                .prefix(categoryLimit - 1)
        )
        let visibleCategories = Set(topCategories.map(\.category))
        let otherAmount = shares
            .filter { !visibleCategories.contains($0.category) }
            .reduce(Decimal.zero) { $0 + $1.amount }

        return topCategories + [CategoryShare(category: aggregateCategory, amount: otherAmount)]
    }

    private static func normalizedCategory(_ category: String) -> String {
        let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let isAggregateCategory = trimmed.compare(
            aggregateCategory,
            options: [.caseInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        ) == .orderedSame
        return isAggregateCategory ? aggregateCategory : trimmed
    }
}

struct MonthlyFlow: Identifiable {
    let id = UUID()
    let month: Date
    let amount: Decimal
    let type: TransactionType
}

struct MoneyChartView: View {
    let transactions: [Transaction]
    let currentMonthOnly: Bool

    private var categoryColors: [Color] {
        [SelfUpStyle.brand, SelfUpStyle.warning, SelfUpStyle.danger, SelfUpStyle.info, SelfUpStyle.success]
    }
    
    private var expenseByCategory: [CategoryShare] {
        let calendar = Calendar.current
        let currentMonthTransactions = transactions.filter {
            if currentMonthOnly {
                return $0.date <= Date() && calendar.isDate($0.date, equalTo: Date(), toGranularity: .month)
            } else {
                return true
            }
        }
        
        return CategoryShare.expenseBreakdown(for: currentMonthTransactions)
    }
    
    private var monthlyFlows: [MonthlyFlow] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions.filter { $0.date <= Date() }) {
            calendar.dateInterval(of: .month, for: $0.date)?.start ?? calendar.startOfDay(for: $0.date)
        }
        var flows: [MonthlyFlow] = []
        for (month, txs) in grouped {
            let income = txs.filter { $0.type == .income }.reduce(Decimal(0)) { $0 + $1.amount }
            let expense = txs.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
            flows.append(MonthlyFlow(month: month, amount: income, type: .income))
            flows.append(MonthlyFlow(month: month, amount: expense, type: .expense))
        }
        return flows.sorted { $0.month < $1.month }
    }

    private var flowAccessibilitySummary: String {
        let income = monthlyFlows.filter { $0.type == .income }.reduce(Decimal.zero) { $0 + $1.amount }
        let expenses = monthlyFlows.filter { $0.type == .expense }.reduce(Decimal.zero) { $0 + $1.amount }
        let months = Set(monthlyFlows.map(\.month)).count
        return "\(months) month\(months == 1 ? "" : "s"). Total income \(NSDecimalNumber(decimal: income).stringValue); total expenses \(NSDecimalNumber(decimal: expenses).stringValue)."
    }

    private var expenseAccessibilitySummary: String {
        let total = expenseByCategory.reduce(Decimal.zero) { $0 + $1.amount }
        guard let largest = expenseByCategory.max(by: { $0.amount < $1.amount }) else {
            return "No expense categories"
        }
        return "Total \(NSDecimalNumber(decimal: total).stringValue) across \(expenseByCategory.count) categories. Largest is \(largest.category) at \(NSDecimalNumber(decimal: largest.amount).stringValue)."
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if !monthlyFlows.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cash Flow Trend")
                        .font(.headline)
                    Chart(monthlyFlows) { flow in
                        BarMark(
                            x: .value("Month", flow.month, unit: .month),
                            y: .value("Amount", Double(truncating: flow.amount as NSDecimalNumber))
                        )
                        .foregroundStyle(by: .value("Type", flow.type == .income ? "Income" : "Expense"))
                        .position(by: .value("Type", flow.type.rawValue))
                    }
                    .chartForegroundStyleScale([
                        "Income": SelfUpStyle.success,
                        "Expense": SelfUpStyle.danger
                    ])
                    .frame(height: 180)
                    .accessibilityLabel("Cash flow trend")
                    .accessibilityValue(flowAccessibilitySummary)
                }
                .premiumCard()
            }
            
            if !expenseByCategory.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Expense Breakdown")
                        .font(.headline)
                    
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: SelfUpStyle.spacingLG) {
                            expenseChart
                            expenseLegend
                        }

                        VStack(alignment: .leading, spacing: SelfUpStyle.spacingMD) {
                            expenseChart
                                .frame(maxWidth: .infinity)
                            expenseLegend
                        }
                    }
                }
                .premiumCard()
            }
        }
    }

    private var expenseChart: some View {
                        Chart(expenseByCategory) { share in
                            SectorMark(
                                angle: .value("Amount", Double(truncating: share.amount as NSDecimalNumber)),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .cornerRadius(4)
                            .foregroundStyle(by: .value("Category", share.category))
                        }
                        .chartForegroundStyleScale(
                            domain: expenseByCategory.map(\.category),
                            range: expenseByCategory.indices.map { categoryColors[$0 % categoryColors.count] }
                        )
                        .frame(width: 140, height: 140)
                        .accessibilityLabel("Expense breakdown")
                        .accessibilityValue(expenseAccessibilitySummary)
    }

    private var expenseLegend: some View {
                        VStack(alignment: .leading, spacing: SelfUpStyle.spacingSM) {
                            ForEach(Array(expenseByCategory.enumerated()), id: \.element.id) { index, share in
                                HStack {
                                    Circle()
                                        .fill(categoryColors[index % categoryColors.count])
                                        .frame(width: 8, height: 8)
                                    Text(share.category)
                                        .font(.caption)
                                        .bold()
                                    Spacer()
                                    Text(share.amount, format: .number.precision(.fractionLength(0)))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
    }
}
