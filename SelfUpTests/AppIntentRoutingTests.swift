import XCTest
@testable import SelfUp

final class AppIntentRoutingTests: XCTestCase {
    func testOpenSectionIntentRoutesToMoney() {
        let router = AppRouter()
        router.navigate(to: .money)
        XCTAssertEqual(router.destination, .money)
    }
}
