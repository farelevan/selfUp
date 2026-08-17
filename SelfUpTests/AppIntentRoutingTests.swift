import XCTest
@testable import SelfUp

final class AppIntentRoutingTests: XCTestCase {
    func testOpenSectionIntentRoutesToMoney() {
        let router = AppRouter()
        router.navigate(to: .money)
        XCTAssertEqual(router.destination, .money)
    }

    func testInsightsRouteUsesProgressHubAndPresentsInsights() {
        let router = AppRouter()

        router.navigate(to: .insights)

        XCTAssertEqual(router.destination, .rewards)
        XCTAssertTrue(router.shouldPresentInsights)

        router.navigate(to: .money)

        XCTAssertEqual(router.destination, .money)
        XCTAssertFalse(router.shouldPresentInsights)
    }
}
