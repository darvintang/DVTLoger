import XCTest
@testable import DVTLoger

/// 日志
let eLoger = {
    let loger = Loger("Test")
    loger.logExpire = 3600 * 24 * 7 // 七天有效时间
    loger.maxFilesCount = 1 // 只保留一个日志文件
    loger.toFileLevel = .default // 所有日志都写入文件
    loger.autoCleanLogFiles() // 第一次使用的时候就进行自动清理
    return loger
}()

final class DVTLogerTests: XCTestCase {
    func testExample() throws {
        eLoger.notice("123")
        eLoger.info("123")
        eLoger.debug("123")
        eLoger.warning("123")
        eLoger.error("123")
        eLoger.fault("123")
    }
}
