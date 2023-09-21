//
//  DVTLoger.swift
//
//
//  Created by darvin on 2018/1/3.
//

/*

 MIT License

 Copyright (c) 2022 darvin http://blog.tcoding.cn

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.

 */

import os
import Zip
import Foundation

public class Loger {
    // MARK: Lifecycle
    public convenience init(_ logDirectory: String = "", logerName: String) {
        self.init(logerName)
        self._logDirectory = logDirectory
    }

    public required init(_ name: String? = nil) {
        self.dateFormatter.locale = Locale.current
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        self.dateShortFormatter.locale = Locale.current
        self.dateShortFormatter.dateFormat = "HH:mm:ss.SSS"
        self._logerName = name
    }

    // MARK: Public
    public enum Level: Int, Comparable {
        @available(*, deprecated, renamed: "default", message: "该属性已经弃用")
        case all = -1
        case `default` = 0 // "✫" `notice`
        case info = 1 // "✯" info
        case debug = 2 // "✬" debug
        case error = 16 // "✮" error
        case fault = 17 // "✭" fault

        case off = 128

        // MARK: Public
        public typealias RawValue = Int

        public static var alls: [Level] = [.default, .info, .debug, .error, .fault, .off]

        public var name: String {
            switch self {
                case .default: return "Notice"
                case .info: return "Info"
                case .debug: return "Debug"
                case .error: return "Error"
                case .fault: return "Fault"
                case .off: return "Off"
                default: return ""
            }
        }

        public var logo: String {
            switch self {
                case .default: return "✫"
                case .info: return "✯"
                case .debug: return "✬"
                case .error: return "✮"
                case .fault: return "✭"
                default: return ""
            }
        }

        public static func < (lhs: Level, rhs: Level) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    /// 是否打印时间戳
    public var isShowLongTime = true

    /// 是否打印日志等级
    public var isShowLevel = true
    /// 是否打印线程
    public var isShowThread = true

    /// 是否打印调用所在的函数名字
    public var isShowFunctionName = true

    /// 是否打印调用所在的行数
    public var isShowLineNumber = true

    /// 是否打印文件名
    public var isShowFileName = true

    public var logLevel: Level = .default

    /// 写入文件的日志等级
    public var toFileLevel: Level = .error

    /// 文件名字格式，支持Y(year)、WY(weekOfYear)、M(month)、D(day)
    /// 例如，以2018/3/21为例 "Y-WY"=>2018Y-12WY "Y-M-D"=>2018Y-3M-21D "Y-M"=>2018Y-3M
    /// 通过这类的组合可以构成一个日志文件保存一天、一周、一个月、一年等方式。建议使用"Y-WY" or "Y-M"，一定要用"-"隔开
    public var fileFormatter = "Y-WY" {
        willSet {
            var list = newValue.components(separatedBy: "-")
            list.removeAll(where: { ["Y", "WY", "M", "D"].contains($0) })
            if !list.isEmpty {
                self.fileFormatter = "Y-WY"
                assertionFailure("不支持的日志文件格式：\(newValue)")
            }
        }
    }

    /// 同等级日志文件数量，避免用户长时间没有打开，然后打开后日志文件就立马被清理了
    public var maxFilesCount = 2 {
        didSet {
            if oldValue < self.maxFilesCount {
                self.autoCleanLogFiles()
            }
        }
    }

    /// 日志超时时间(秒)，当日志文件创建的时间超过这个时间并且文件数量也大于设定值就会删除，配合自动清理使用
    public var logExpire: TimeInterval = 3600 * 24 * 30 {
        didSet {
            if oldValue < self.logExpire {
                self.autoCleanLogFiles()
            }
        }
    }

    public var logerName: String {
        self._logerName ?? Bundle.main.bundleIdentifier?.components(separatedBy: ".").last?.capitalized ?? "Default"
    }

    // MARK: Fileprivate
    fileprivate let dateFormatter = DateFormatter()
    fileprivate let dateShortFormatter = DateFormatter()

    fileprivate var _logerName: String?
    fileprivate var _logDirectory: String?

    fileprivate var logDirectory: String {
        self._logDirectory ?? self.logerName
    }
}

public extension Loger {
    // MARK: Internal
    /// 获取日志文件夹的路径，没有该文件夹就创建
    /// - Returns: 日志文件夹的路径
    static func getLogDirectory() -> String {
        let logDirectoryPath = NSHomeDirectory() + "/Documents/DVTLoger"
        if !FileManager.default.fileExists(atPath: logDirectoryPath) {
            try? FileManager.default.createDirectory(atPath: logDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        }
        return logDirectoryPath
    }

    /// 获取所有日志文件的路径
    /// - Returns: 所有日志文件的路径
    static func getLogFilesPath() -> [String] {
        var filesPath = [String]()
        do {
            filesPath = try FileManager.default.contentsOfDirectory(atPath: self.getLogDirectory())
        } catch { }
        return filesPath.compactMap { self.getLogDirectory() + "/\($0)" }
    }

    /// 清理所有日志文件
    static func cleanAll() {
        do { try FileManager.default.removeItem(atPath: self.getLogDirectory()) } catch { }
    }

    /// 通过日志等级获取当前日志文件的路径
    /// - Parameter level: 日志等级
    /// - Returns: 文件路径
    func getCurrentLogFilePath(_ level: Level) -> String {
        let fileName = selfLoger.returnFileName(level)
        let logFilePath = self.getLogDirectory() + "/" + fileName
        if !FileManager.default.fileExists(atPath: logFilePath) {
            FileManager.default.createFile(atPath: logFilePath, contents: nil, attributes: nil)
        }
        return logFilePath
    }

    /// 获取日志文件夹的路径，没有该文件夹就创建
    /// - Returns: 日志文件夹的路径
    func getLogDirectory() -> String {
        let logDirectoryPath = Self.getLogDirectory() + "/" + self.logDirectory
        if !FileManager.default.fileExists(atPath: logDirectoryPath) {
            try? FileManager.default.createDirectory(atPath: logDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        }
        return logDirectoryPath
    }

    /// 获取所有日志文件的路径
    /// - Returns: 所有日志文件的路径
    func getLogFilesPath() -> [String] {
        var filesPath = [String]()
        do {
            filesPath = try FileManager.default.contentsOfDirectory(atPath: self.getLogDirectory())
        } catch { }
        return filesPath.compactMap { self.getLogDirectory() + "/\($0)" }
    }

    /// 清理日志文件
    /// - Returns: 操作结果
    @discardableResult func cleanLogFiles() -> Bool {
        self.getLogFilesPath().forEach { path in
            do { try FileManager.default.removeItem(atPath: self.getLogDirectory() + "/" + path) } catch { }
        }
        return self.getLogFilesPath().isEmpty
    }

    /// 在设置日志过期时间之后调用，如果需要清理请手动调用
    func autoCleanLogFiles() {
        let filesList = self.getLogFilesPath()
        self.cleanLogFiles(.default, filesList: filesList)
        self.cleanLogFiles(.debug, filesList: filesList)
        self.cleanLogFiles(.info, filesList: filesList)
        self.cleanLogFiles(.error, filesList: filesList)
        self.cleanLogFiles(.fault, filesList: filesList)
    }

    // MARK: Fileprivate
    fileprivate func cleanLogFiles(_ level: Level, filesList: [String]) {
        let name = level.name.lowercased()
        let files = filesList.filter { $0.contains(name) }
        if files.count > self.maxFilesCount {
            files.forEach { path in
                if let attributes = try? FileManager.default.attributesOfItem(atPath: path), let creationDate = attributes[.creationDate] as? Date {
                    if creationDate.timeIntervalSinceNow * -1 > self.logExpire {
                        try? FileManager.default.removeItem(atPath: path)
                    }
                }
            }
        }
    }

    fileprivate func dvt_printToConsole(_ string: String, level: Level) {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "DVTLoger"
        if #available(iOS 14.0, macOS 11.0,*) {
            let logger = Logger(subsystem: bundleIdentifier, category: "\(self.logerName)")
            logger.log(level: OSLogType(UInt8(level.rawValue)), "\((self.isShowLevel ? level.logo + " " : "") + string, privacy: .auto)")
        } else {
            os_log("%{public}@: %{public}@", log: .init(subsystem: bundleIdentifier, category: "\(self.logerName)"), type: OSLogType(UInt8(level.rawValue)), "\(self.logerName)", (self.isShowLevel ? level.logo + " " : "") + string)
        }
    }

    fileprivate func printToFile(_ level: Level, log string: String) {
        if self.toFileLevel > level {
            return
        }
        let logFilePath = self.getCurrentLogFilePath(level)
        if FileManager.default.fileExists(atPath: logFilePath) {
            let writeHandler = FileHandle(forWritingAtPath: logFilePath)
            writeHandler?.seekToEndOfFile()
            if let data = ("\n" + string).data(using: .utf8) {
                writeHandler?.write(data)
            }
            writeHandler?.closeFile()
        } else {
            FileManager.default.createFile(atPath: logFilePath, contents: string.data(using: .utf8), attributes: nil)
        }
    }

    fileprivate func returnFileName(_ level: Level) -> String {
        var fileNameString = level.name.lowercased()
        let dateComponents = Calendar.current.dateComponents(Set<Calendar.Component>.init(arrayLiteral: .year, .month, .day, .weekOfYear), from: Date())
        let fileFormatters = self.fileFormatter.components(separatedBy: "-")
        if fileFormatters.contains("Y") {
            fileNameString += "-\(dateComponents.year!)"
        }
        if fileFormatters.contains("M") {
            fileNameString += "-\(dateComponents.month!)"
        }
        if fileFormatters.contains("WY") {
            fileNameString += "-\(dateComponents.weekOfYear!)"
        }
        if fileFormatters.contains("D") {
            fileNameString += "-\(dateComponents.day!)"
        }
        fileNameString += ".log"
        return fileNameString
    }
}

public extension Loger {
    /// 打印日志
    /// - Parameters:
    ///   - level: 日志等级
    ///   - format: 要打印的数据的结构
    ///   - args: 要打印的数据数组
    /// - Returns: 打印的内容
    func log(_ level: Level,
             function: String = #function,
             file: String = #file,
             line: Int = #line,
             values: Any...,
             separator: String = " ") -> String {
        if self.logLevel > level {
            return ""
        }

        let dateTime = self.isShowLongTime ? "\(self.dateFormatter.string(from: Date()))" : "\(self.dateShortFormatter.string(from: Date()))"
        var fileString = ""
        if self.isShowFileName {
            fileString += "[" + (file as NSString).lastPathComponent
            if self.isShowLineNumber {
                fileString += ":\(line)"
            }
            fileString += "]"
        }
        if fileString.isEmpty && self.isShowLineNumber {
            fileString = "line:\(line)"
        }
        let functionString = self.isShowFunctionName ? function : ""

        let threadID = String(unsafeBitCast(Thread.current, to: Int.self), radix: 16, uppercase: false)
        let isMain = self.isShowThread ? Thread.current.isMainThread ? "[Main]" : "[Global]<0x\(threadID)>" : ""
        let infoString = "\(fileString) \(isMain) \(functionString)".trimmingCharacters(in: CharacterSet(charactersIn: " "))

        var logString = ""
        values.forEach { tempValue in
            var tempLog = ""
            Swift.print(tempValue, terminator: separator, to: &tempLog)
            logString += tempLog
        }

        logString = infoString + (infoString.isEmpty ? "=>" : "\n=> ") + logString

        self.dvt_printToConsole(logString, level: level)

        logString = "\(dateTime) [\(self.logerName)] " + logString
        self.printToFile(level, log: logString)
        return logString + "\n"
    }
}

public extension Loger {
    @discardableResult func notice(function: String = #function,
                                   file: String = #file,
                                   line: Int = #line,
                                   _ values: Any...,
                                   separator: String = " ") -> String {
        return self.log(.default, function: function, file: file, line: line, values: values, separator: separator)
    }

    @discardableResult func info(function: String = #function,
                                 file: String = #file,
                                 line: Int = #line,
                                 _ values: Any...,
                                 separator: String = " ") -> String {
        return self.log(.info, function: function, file: file, line: line, values: values, separator: separator)
    }

    @discardableResult func debug(function: String = #function,
                                  file: String = #file,
                                  line: Int = #line,
                                  _ values: Any...,
                                  separator: String = " ") -> String {
        return self.log(.debug, function: function, file: file, line: line, values: values, separator: separator)
    }

    @available(*, deprecated, message: "该方法已经弃用")
    @discardableResult func warning(function: String = #function,
                                    file: String = #file,
                                    line: Int = #line,
                                    _ values: Any...,
                                    separator: String = " ") -> String {
        return self.log(.error, function: function, file: file, line: line, values: values, separator: separator)
    }

    @discardableResult func error(function: String = #function,
                                  file: String = #file,
                                  line: Int = #line,
                                  _ values: Any...,
                                  separator: String = " ") -> String {
        return self.log(.error, function: function, file: file, line: line, values: values, separator: separator)
    }

    @discardableResult func fault(function: String = #function,
                                  file: String = #file,
                                  line: Int = #line,
                                  _ values: Any...,
                                  separator: String = " ") -> String {
        return self.log(.fault, function: function, file: file, line: line, values: values, separator: separator)
    }
}

private let selfLoger = Loger()
public extension Loger {
    static var `default`: Loger = selfLoger

    @discardableResult static func notice(function: String = #function,
                                          file: String = #file,
                                          line: Int = #line,
                                          _ values: Any...,
                                          separator: String = " ") -> String {
        return selfLoger.log(.default, function: function, file: file, line: line, values: values, separator: separator)
    }

    @discardableResult static func info(function: String = #function,
                                        file: String = #file,
                                        line: Int = #line,
                                        _ values: Any...,
                                        separator: String = " ") -> String {
        return selfLoger.log(.info, function: function, file: file, line: line, values: values, separator: separator)
    }

    @discardableResult static func debug(function: String = #function,
                                         file: String = #file,
                                         line: Int = #line,
                                         _ values: Any...,
                                         separator: String = " ") -> String {
        return selfLoger.log(.debug, function: function, file: file, line: line, values: values, separator: separator)
    }

    @available(*, deprecated, message: "该方法已经弃用")
    @discardableResult static func warning(function: String = #function,
                                           file: String = #file,
                                           line: Int = #line,
                                           _ values: Any...,
                                           separator: String = " ") -> String {
        return selfLoger.log(.error, function: function, file: file, line: line, values: values, separator: separator)
    }

    @discardableResult static func error(function: String = #function,
                                         file: String = #file,
                                         line: Int = #line,
                                         _ values: Any...,
                                         separator: String = " ") -> String {
        return selfLoger.log(.error, function: function, file: file, line: line, values: values, separator: separator)
    }

    @discardableResult static func fault(function: String = #function,
                                         file: String = #file,
                                         line: Int = #line,
                                         _ values: Any...,
                                         separator: String = " ") -> String {
        return selfLoger.log(.fault, function: function, file: file, line: line, values: values, separator: separator)
    }
}

#if canImport(UIKit)
    import UIKit

    public extension Loger {
        static func getLogerFileZip(_ completion: @escaping (_ error: Error?, _ path: String?) -> Void) {
            let zipFilePath = self.getLogDirectory() + ".zip"
            try? FileManager.default.removeItem(atPath: zipFilePath)
            let paths = self.getLogFilesPath().compactMap { URL(fileURLWithPath: $0) }
            do {
                try Zip.zipFiles(paths: paths, zipFilePath: URL(fileURLWithPath: zipFilePath), password: nil) { progress in
                    if progress == 1 {
                        completion(nil, zipFilePath)
                    }
                }
            } catch {
                completion(error, nil)
            }
        }

        static func shareLoger(from vc: UIViewController?, completion: ((_ error: Error?, _ path: String?) -> Void)? = nil) {
            self.getLogerFileZip { error, path in
                completion?(error, path)
                if let tpath = path {
                    let actVC = UIActivityViewController(activityItems: [URL(fileURLWithPath: tpath)], applicationActivities: nil)
                    vc?.present(actVC, animated: true, completion: nil)
                }
            }
        }

        func getLogerFileZip(_ completion: @escaping (_ progress: Double, _ path: String) -> Void) {
            let zipFilePath = self.getLogDirectory() + ".zip"
            try? FileManager.default.removeItem(atPath: zipFilePath)
            let paths = self.getLogFilesPath().compactMap { URL(fileURLWithPath: $0) }
            try? Zip.zipFiles(paths: paths, zipFilePath: URL(fileURLWithPath: zipFilePath), password: nil) { progress in
                completion(progress, zipFilePath)
            }
        }

        func shareLoger(from vc: UIViewController?, completion: ((_ progress: Double, _ path: String) -> Void)? = nil) {
            self.getLogerFileZip { progress, path in
                completion?(progress, path)
                if progress == 1 {
                    let actVC = UIActivityViewController(activityItems: [URL(fileURLWithPath: path)], applicationActivities: nil)
                    vc?.present(actVC, animated: true, completion: nil)
                }
            }
        }
    }
#endif
