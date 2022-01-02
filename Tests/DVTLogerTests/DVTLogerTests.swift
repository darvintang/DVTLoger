@testable import DVTLoger
import XCTest

final class DVTLogerTests: XCTestCase {
    func testExample() throws {
        Loger.debug("123")
        Loger.info("123")
        Loger.warning("123")
        Loger.error("123")
    }
}
