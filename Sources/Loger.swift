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

import Foundation
import os
import Zip

public class Loger {
    public enum Level: Int, Comparable {
        public typealias RawValue = Int

        case all = -1
        case debug = 1 // "🟢"
        case info = 2 // "⚪"
        case warning = 3 // "🟡"
        case error = 4 // "🔴"
        case off = 999

        public static func < (lhs: Level, rhs: Level) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

        public static func <= (lhs: Level, rhs: Level) -> Bool {
            return lhs.rawValue >= rhs.rawValue
        }

        public static func > (lhs: Level, rhs: Level) -> Bool {
            return lhs.rawValue > rhs.rawValue
        }

        public static func == (lhs: Level, rhs: Level) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }

        public var name: String {
            switch self {
                case .all: return "All"
                case .debug: return "Debug"
                case .info: return "Info"
                case .warning: return "Warning"
                case .error: return "Error"
                case .off: return "Off"
            }
        }

        public static var alls: [Level] = [.all, .debug, .info, .warning, .error, .off]
    }

    fileprivate let dateFormatter = DateFormatter()
    fileprivate let dateShortFormatter = DateFormatter()

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
    public var maxFilesCount: Int = 2 {
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

    /// 是否输出到控制台
    public var toConsole = false

    public var logLevel: Level = .all

    /// 写入文件的日志等级
    public var toFileLevel: Level = .warning

    fileprivate var _logerName: String?
    public var logerName: String {
        self._logerName ?? Bundle.main.bundleIdentifier?.components(separatedBy: ".").last?.capitalized ?? "Default"
    }

    fileprivate var _logDirectory: String?
    fileprivate var logDirectory: String {
        self._logDirectory ?? self.logerName
    }

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
}

extension Loger {
    /// 通过日志等级获取当前日志文件的路径
    /// - Parameter level: 日志等级
    /// - Returns: 文件路径
    public func getCurrentLogFilePath(_ level: Level) -> String {
        let fileName = selfLoger.returnFileName(level)
        let logFilePath = self.getLogDirectory() + "/" + fileName
        if !FileManager.default.fileExists(atPath: logFilePath) {
            FileManager.default.createFile(atPath: logFilePath, contents: nil, attributes: nil)
        }
        return logFilePath
    }

    /// 获取日志文件夹的路径，没有该文件夹就创建
    /// - Returns: 日志文件夹的路径
    public func getLogDirectory() -> String {
        let logDirectoryPath = Self.getLogDirectory() + "/" + self.logDirectory
        if !FileManager.default.fileExists(atPath: logDirectoryPath) {
            try? FileManager.default.createDirectory(atPath: logDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        }
        return logDirectoryPath
    }

    /// 获取所有日志文件的路径
    /// - Returns: 所有日志文件的路径
    public func getLogFilesPath() -> [String] {
        var filesPath = [String]()
        do {
            filesPath = try FileManager.default.contentsOfDirectory(atPath: self.getLogDirectory())
        } catch {}
        return filesPath.compactMap({ self.getLogDirectory() + "/\($0)" })
    }

    /// 获取日志文件夹的路径，没有该文件夹就创建
    /// - Returns: 日志文件夹的路径
    public static func getLogDirectory() -> String {
        let logDirectoryPath = NSHomeDirectory() + "/Documents/DVTLoger"
        if !FileManager.default.fileExists(atPath: logDirectoryPath) {
            try? FileManager.default.createDirectory(atPath: logDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        }
        return logDirectoryPath
    }

    /// 获取所有日志文件的路径
    /// - Returns: 所有日志文件的路径
    public static func getLogFilesPath() -> [String] {
        var filesPath = [String]()
        do {
            filesPath = try FileManager.default.contentsOfDirectory(atPath: self.getLogDirectory())
        } catch {}
        return filesPath.compactMap({ self.getLogDirectory() + "/\($0)" })
    }

    /// 清理日志文件
    /// - Returns: 操作结果
    @discardableResult public func cleanLogFiles() -> Bool {
        self.getLogFilesPath().forEach { path in
            do { try FileManager.default.removeItem(atPath: self.getLogDirectory() + "/" + path) } catch {}
        }
        return self.getLogFilesPath().isEmpty
    }

    /// 在设置日志过期时间之后调用，如果需要清理请手动调用
    public func autoCleanLogFiles() {
        let filesList = self.getLogFilesPath()
        self.cleanLogFiles(.debug, filesList: filesList)
        self.cleanLogFiles(.info, filesList: filesList)
        self.cleanLogFiles(.warning, filesList: filesList)
        self.cleanLogFiles(.error, filesList: filesList)
    }

    fileprivate func cleanLogFiles(_ level: Level, filesList: [String]) {
        let name = level.name.lowercased()
        let files = filesList.filter({ $0.contains(name) })
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

    /// 清理所有日志文件
    public static func cleanAll() {
        do { try FileManager.default.removeItem(atPath: self.getLogDirectory()) } catch {}
    }

    fileprivate func dvt_printToConsole(_ string: String) {
        if #available(iOS 14.0, macOS 11.0,*) {
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                let logger = Logger(subsystem: bundleIdentifier, category: "\(self.logerName)")
                logger.log("\(string, privacy: .public)")
            }
        } else {
            os_log("%{public}@: %{public}@", log: .default, type: .info, "\(self.logerName)", string)
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
        var fileNameString = ""
        switch level {
            case .info:
                fileNameString = "info"
            case .debug:
                fileNameString = "debug"
            case .warning:
                fileNameString = "warning"
            case .error:
                fileNameString = "error"
            default:
                break
        }
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

extension Loger {
    /// 打印日志
    /// - Parameters:
    ///   - level: 日志等级
    ///   - format: 要打印的数据的结构
    ///   - args: 要打印的数据数组
    /// - Returns: 打印的内容
    public func log(_ level: Level,
                    function: String = #function,
                    file: String = #file,
                    line: Int = #line,
                    values: Any...,
                    separator: String = " ") -> String {
        if self.logLevel > level {
            return ""
        }

        let dateTime = self.isShowLongTime ? "\(self.dateFormatter.string(from: Date()))" : "\(self.dateShortFormatter.string(from: Date()))"
        var levelString = ""
        switch level {
            case .debug:
                levelString += "🟢"
            case .info:
                levelString += "⚪"
            case .warning:
                levelString += "🟡"
            case .error:
                levelString += "🔴"
            default:
                break
        }
        levelString = self.isShowLevel ? levelString : ""

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

        let threadId = String(unsafeBitCast(Thread.current, to: Int.self), radix: 16, uppercase: false)
        let isMain = self.isShowThread ? Thread.current.isMainThread ? "[Main]" : "[Global]<0x\(threadId)>" : ""
        let infoString = "\(levelString) \(fileString) \(isMain) \(functionString)".trimmingCharacters(in: CharacterSet(charactersIn: " "))

        var logString = ""
        values.forEach { tempValue in
            var tempLog = ""
            Swift.print(tempValue, terminator: separator, to: &tempLog)
            logString += tempLog
        }

        logString = infoString + (infoString.isEmpty ? "" : " => ") + logString

        if self.toConsole {
            self.dvt_printToConsole(logString)
        } else {
            Swift.print("\(dateTime) [\(self.logerName)] " + logString)
        }

        logString = "\(dateTime) [\(self.logerName)] " + logString
        self.printToFile(level, log: logString)
        return logString + "\n"
    }
}

extension Loger {
    @discardableResult public func info(function: String = #function,
                                        file: String = #file,
                                        line: Int = #line,
                                        _ values: Any...,
                                        separator: String = " ") -> String {
        return self.log(.info, function: function, file: file, line: line, values: values, separator: separator)
    }

    @discardableResult public func debug(function: String = #function,
                                         file: String = #file,
                                         line: Int = #line,
                                         _ values: Any...,
                                         separator: String = " ") -> String {
        return self.log(.debug, function: function, file: file, line: line, values: values, separator: separator)
    }

    @discardableResult public func warning(function: String = #function,
                                           file: String = #file,
                                           line: Int = #line,
                                           _ values: Any...,
                                           separator: String = " ") -> String {
        return self.log(.warning, function: function, file: file, line: line, values: values, separator: separator)
    }

    @discardableResult public func error(function: String = #function,
                                         file: String = #file,
                                         line: Int = #line,
                                         _ values: Any...,
                                         separator: String = " ") -> String {
        return self.log(.error, function: function, file: file, line: line, values: values, separator: separator)
    }
}

fileprivate let selfLoger = Loger()
extension Loger {
    public static var `default`: Loger = selfLoger

    @discardableResult public static func info(function: String = #function,
                                               file: String = #file,
                                               line: Int = #line,
                                               _ values: Any...,
                                               separator: String = " ") -> String {
        return selfLoger.log(.info, function: function, file: file, line: line, values: values, separator: separator)
    }

    @discardableResult public static func debug(function: String = #function,
                                                file: String = #file,
                                                line: Int = #line,
                                                _ values: Any...,
                                                separator: String = " ") -> String {
        return selfLoger.log(.debug, function: function, file: file, line: line, values: values, separator: separator)
    }

    @discardableResult public static func warning(function: String = #function,
                                                  file: String = #file,
                                                  line: Int = #line,
                                                  _ values: Any...,
                                                  separator: String = " ") -> String {
        return selfLoger.log(.warning, function: function, file: file, line: line, values: values, separator: separator)
    }

    @discardableResult public static func error(function: String = #function,
                                                file: String = #file,
                                                line: Int = #line,
                                                _ values: Any...,
                                                separator: String = " ") -> String {
        return selfLoger.log(.error, function: function, file: file, line: line, values: values, separator: separator)
    }
}

#if canImport(UIKit)
    import UIKit

    extension Loger {
        public func getLogerFileZip(_ completion: @escaping (_ progress: Double, _ path: String) -> Void) {
            let zipFilePath = self.getLogDirectory() + ".zip"
            try? FileManager.default.removeItem(atPath: zipFilePath)
            let paths = self.getLogFilesPath().compactMap { URL(fileURLWithPath: $0) }
            try? Zip.zipFiles(paths: paths, zipFilePath: URL(fileURLWithPath: zipFilePath), password: nil) { progress in
                completion(progress, zipFilePath)
            }
        }

        public func shareLoger(from vc: UIViewController?, completion: ((_ progress: Double, _ path: String) -> Void)? = nil) {
            self.getLogerFileZip { progress, path in
                completion?(progress, path)
                if progress == 1 {
                    let actVC = UIActivityViewController(activityItems: [URL(fileURLWithPath: path)], applicationActivities: nil)
                    vc?.present(actVC, animated: true, completion: nil)
                }
            }
        }

        public static func getLogerFileZip(_ completion: @escaping (_ error: Error?, _ path: String?) -> Void) {
            let zipFilePath = self.getLogDirectory() + ".zip"
            try? FileManager.default.removeItem(atPath: zipFilePath)
            let paths = self.getLogFilesPath().compactMap { URL(fileURLWithPath: $0) }
            do {
                try Zip.zipFiles(paths: paths, zipFilePath: URL(fileURLWithPath: zipFilePath), password: nil) { progress in
                    if progress == 1 {
                        completion(nil, zipFilePath)
                    }
                }
            } catch let error {
                completion(error, nil)
            }
        }

        public static func shareLoger(from vc: UIViewController?, completion: ((_ error: Error?, _ path: String?) -> Void)? = nil) {
            self.getLogerFileZip { error, path in
                completion?(error, path)
                if let tpath = path {
                    let actVC = UIActivityViewController(activityItems: [URL(fileURLWithPath: tpath)], applicationActivities: nil)
                    vc?.present(actVC, animated: true, completion: nil)
                }
            }
        }
    }
#endif
