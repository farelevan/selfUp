import Foundation
import SwiftData

@Model final class SavingGoal {
    var id: UUID
    var title: String
    var targetAmount: Decimal
    var currentAmount: Decimal
    var createdAt: Date
    
    init(title: String, targetAmount: Decimal, currentAmount: Decimal = 0.0, createdAt: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.createdAt = createdAt
    }
}
