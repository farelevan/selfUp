import Foundation
import SwiftData

enum TransactionType: String, Codable, CaseIterable {
    case income
    case expense
}

@Model final class Transaction {
    var id: UUID
    var amount: Decimal
    var type: TransactionType
    var category: String
    var note: String
    var date: Date
    
    init(amount: Decimal, type: TransactionType, category: String, note: String = "", date: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.type = type
        self.category = category
        self.note = note
        self.date = date
    }
}
