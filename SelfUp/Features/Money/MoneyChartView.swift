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
                VStack(alignment: .leading) {
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
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if !expenseByCategory.isEmpty {
                VStack(alignment: .leading) {
                    Text("Expense Breakdown")
                        .font(.headline)
                    Chart(expenseByCategory) { share in
                        BarMark(
                            x: .value("Amount", Double(truncating: share.amount as NSDecimalNumber)),
                            y: .value("Category", share.category)
                        )
                        .foregroundStyle(Color.red.opacity(0.8))
                    }
                    .frame(height: min(300, max(120, Double(expenseByCategory.count) * 35)))
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
