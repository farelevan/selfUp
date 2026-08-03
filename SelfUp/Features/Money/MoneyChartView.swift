import SwiftUI
import Charts

struct CategoryShare: Identifiable {
    let id = UUID()
    let category: String
    let amount: Decimal
}

struct MonthlyFlow: Identifiable {
    let id = UUID()
    let month: String
    let amount: Decimal
    let type: TransactionType
}

struct MoneyChartView: View {
    let transactions: [Transaction]
    let currentMonthOnly: Bool
    
    private var expenseByCategory: [CategoryShare] {
        let calendar = Calendar.current
        let currentMonthTransactions = transactions.filter {
            if currentMonthOnly {
                return calendar.isDate($0.date, equalTo: Date(), toGranularity: .month)
            } else {
                return true
            }
        }
        
        let expenses = currentMonthTransactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return grouped.map { (cat, txs) in
            CategoryShare(category: cat, amount: txs.reduce(Decimal(0)) { $0 + $1.amount })
        }.sorted { $0.amount > $1.amount }
    }
    
    private var monthlyFlows: [MonthlyFlow] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yy"
        
        let grouped = Dictionary(grouping: transactions, by: { formatter.string(from: $0.date) })
        var flows: [MonthlyFlow] = []
        for (month, txs) in grouped {
            let income = txs.filter { $0.type == .income }.reduce(Decimal(0)) { $0 + $1.amount }
            let expense = txs.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
            flows.append(MonthlyFlow(month: month, amount: income, type: .income))
            flows.append(MonthlyFlow(month: month, amount: expense, type: .expense))
        }
        return flows.sorted { f1, f2 in
            guard let d1 = formatter.date(from: f1.month), let d2 = formatter.date(from: f2.month) else { return false }
            return d1 < d2
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if !monthlyFlows.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cash Flow Trend")
                        .font(.headline)
                    Chart(monthlyFlows) { flow in
                        BarMark(
                            x: .value("Month", flow.month),
                            y: .value("Amount", Double(truncating: flow.amount as NSDecimalNumber))
                        )
                        .foregroundStyle(by: .value("Type", flow.type == .income ? "Income" : "Expense"))
                        .position(by: .value("Type", flow.type.rawValue))
                    }
                    .chartForegroundStyleScale([
                        "Income": Color.green,
                        "Expense": Color.red
                    ])
                    .frame(height: 180)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            if !expenseByCategory.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Expense Breakdown")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        // Donut/Pie Chart
                        Chart(expenseByCategory) { share in
                            SectorMark(
                                angle: .value("Amount", Double(truncating: share.amount as NSDecimalNumber)),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .cornerRadius(4)
                            .foregroundStyle(by: .value("Category", share.category))
                        }
                        .frame(width: 140, height: 140)
                        
                        // Custom Legend or Details
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(expenseByCategory.prefix(4)) { share in
                                HStack {
                                    Circle()
                                        .frame(width: 8, height: 8)
                                    Text(share.category)
                                        .font(.caption)
                                        .bold()
                                    Spacer()
                                    Text(share.amount, format: .number.precision(.fractionLength(0)))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
