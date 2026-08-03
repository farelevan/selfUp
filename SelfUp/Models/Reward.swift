import Foundation
import SwiftData

@Model final class Reward {
    var id: UUID
    var title: String
    var xpCost: Int
    var redeemedAt: Date?
    
    init(title: String, xpCost: Int, redeemedAt: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.xpCost = xpCost
        self.redeemedAt = redeemedAt
    }
}
