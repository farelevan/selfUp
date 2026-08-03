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
