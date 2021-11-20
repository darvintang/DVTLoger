//
//  DVTLoger.swift
//
//
//  Created by darvin on 2018/1/3.
//

/*

 MIT License

 Copyright (c) 2021 darvintang http://blog.tcoding.cn

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

public enum LogerLevel: Int {
    public typealias RawValue = Int

    case all = 0
    case info = 1
    case debug = 2
    case warning = 3
    case error = 4
    case off = 5
}

extension LogerLevel: Comparable {
    public static func < (lhs: LogerLevel, rhs: LogerLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public static func <= (lhs: LogerLevel, rhs: LogerLevel) -> Bool {
        return lhs.rawValue <= rhs.rawValue
    }

    public static func >= (lhs: LogerLevel, rhs: LogerLevel) -> Bool {
        return lhs.rawValue >= rhs.rawValue
    }

    public static func > (lhs: LogerLevel, rhs: LogerLevel) -> Bool {
        return lhs.rawValue > rhs.rawValue
    }
}

/// 请在 "Swift Compiler - Custom Flags" 选项查找 "Other Swift Flags" 然后在DEBUG配置那里添加"-D DEBUG".
public class Loger {
    fileprivate let dateFormatter = DateFormatter()
    fileprivate let dateShortFormatter = DateFormatter()

    public var logerName: String
    /// 文件夹
    fileprivate let logDirectory: String

    /// 保存到日志文件的等级
    public var saveFileLevel = LogerLevel.warning
    /// 文件名字格式，支持Y(year)、WY(weekOfYear)、M(month)、D(day) 例如，以2018/3/21为例 "Y-WY"=>2018Y-12WY "Y-M-D"=>2018Y-3M-21D "Y-M"=>2018Y-3M，通过这类的组合可以构成一个日志文件保存一天、一周、一个月、一年等方式。建议使用"Y-WY" or "Y-M"，一定要用"-"隔开
    public var fileFormatter = "Y-WY"
    /// 是否打印时间戳
    public var isShowLongTime = true

    /// 是否打印日志等级
    public var isShowLevel = true
    /// 是否打印线程
    public var isShowThread = true
    /// release模式下默认打印日志的等级
    public var releaseLogLevel: LogerLevel!

    /// debug模式下默认打印日志的等级
    public var debugLogLevel: LogerLevel!

    /// 是否打印文件名
    public var isShowFileName = true

    /// 是否打印调用所在的函数名字
    public var isShowFunctionName = true

    /// 是否打印调用所在的行数
    public var isShowLineNumber = true

    private var logLevel: LogerLevel! {
        #if DEBUG
            return self.debugLogLevel
        #else
            return self.releaseLogLevel
        #endif
    }

    public required init(_ logDirectory: String = "", logerName: String = "default") {
        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        self.dateShortFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateShortFormatter.dateFormat = "HH:mm:ss.SSS"
        self.debugLogLevel = LogerLevel.all
        self.releaseLogLevel = LogerLevel.warning
        self.logDirectory = logDirectory.appending("/\(logerName)/").replacingOccurrences(of: "//", with: "/")
        self.logerName = logerName
    }
}

extension Loger {
    /// 通过日志等级获取当前日志文件的路径
    /// - Parameter level: 日志等级
    /// - Returns: 文件路径
    public func getCurrentLogFilePath(_ level: LogerLevel) -> String {
        let fileName = selfLoger.returnFileName(level)
        let logFilePath = self.getLogDirectory() + fileName
        if !FileManager.default.fileExists(atPath: logFilePath) {
            FileManager.default.createFile(atPath: logFilePath, contents: nil, attributes: nil)
        }
        return logFilePath
    }

    /// 获取日志文件夹的路径，没有该文件夹就创建
    /// - Returns: 日志文件夹的路径
    public func getLogDirectory() -> String {
        let logDirectoryPath = NSHomeDirectory() + "/Documents/DVTLoger/" + self.logDirectory
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
        return filesPath
    }

    /// 清理日志文件
    /// - Returns: 操作结果
    @discardableResult public func cleanLogFiles() -> Bool {
        self.getLogFilesPath().forEach { path in
            do { try FileManager.default.removeItem(atPath: self.getLogDirectory() + "/" + path) } catch {}
        }
        return self.getLogFilesPath().isEmpty
    }

    fileprivate func xt_print(_ string: String) {
        #if DEBUG
            print(string)
        #endif
    }

    fileprivate func printToFile(_ level: LogerLevel, log string: String) {
        if self.logLevel > level {
            return
        }
        let logFilePath = self.getCurrentLogFilePath(level)
        if FileManager.default.fileExists(atPath: logFilePath) {
            let writeHandler = FileHandle(forWritingAtPath: logFilePath)
            writeHandler?.seekToEndOfFile()
            if let data = ("\n" + string).data(using: String.Encoding.utf8) {
                writeHandler?.write(data)
            }
            writeHandler?.closeFile()
        } else {
            FileManager.default.createFile(atPath: logFilePath, contents: string.data(using: String.Encoding.utf8), attributes: nil)
        }
    }

    fileprivate func returnFileName(_ level: LogerLevel) -> String {
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
        fileFormatters.forEach { string in
            switch string {
                case "D":
                    fileNameString += "-\(dateComponents.day!)"
                case "WY":
                    fileNameString += "-\(dateComponents.weekOfYear!)"
                case "M":
                    fileNameString += "-\(dateComponents.month!)"
                case "Y":
                    fileNameString += "-\(dateComponents.year!)"
                default:
                    break
            }
        }
        fileNameString += ".log"
        return fileNameString
    }
}

extension Loger {
    fileprivate func loger(format: String, _ args: [Any?]) -> String {
        guard let ranges = try? NSRegularExpression(pattern: "%*%", options: []) else {
            return ""
        }

        let matches = ranges.matches(in: format, options: [], range: NSRange(format.startIndex..., in: format))

        var value = ""
        var index = 0
        if args.isEmpty {
            return format
        }

        for i in 0 ..< matches.count {
            let len = (i < matches.count - 1 ? matches[i + 1].range.location : format.count) - matches[i].range.location
            let range = Range(NSMakeRange(matches[i].range.location, len), in: format)
            if let tempRange = range {
                var tempFormat = "\(format[tempRange])"
                if !tempFormat.hasPrefix("% ") && index < args.count {
                    let arg = args[index]
                    index = index + 1
                    if arg != nil, let cVarArg = arg as? CVarArg {
                        tempFormat = String(format: tempFormat, cVarArg)
                    } else {
                        switch arg {
                            case let .some(tempArg):
                                tempFormat = String(format: tempFormat, "\(tempArg)")
                            case .none:
                                tempFormat = String(format: tempFormat, "nil")
                        }
                    }
                }
                value = value + tempFormat
            }
        }
        return value
    }

    /// 打印日志
    /// - Parameters:
    ///   - level: 日志等级
    ///   - format: 要打印的数据的结构
    ///   - args: 要打印的数据数组
    /// - Returns: 打印的内容
    fileprivate func log(_ level: LogerLevel,
                         function: String,
                         file: String,
                         line: Int,
                         value: [Any],
                         separator: String) -> String {
        if self.logLevel > level {
            return ""
        }

        let dateTime = self.isShowLongTime ? "\(self.dateFormatter.string(from: Date()))" : "\(self.dateShortFormatter.string(from: Date()))"
        var levelString = "[\(self.logerName)] "
        switch level {
            case .info:
                levelString += "[📠]"
            case .debug:
                levelString += "[📎]"
            case .warning:
                levelString += "[❗️]"
            case .error:
                levelString += "[✖️]"
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
        let infoString = "\(dateTime) \(levelString) \(fileString) \(isMain) \(functionString)".trimmingCharacters(in: CharacterSet(charactersIn: " "))
        var logString = ""
        value.forEach { tempValue in
            var tempLog = ""
            print(tempValue, terminator: separator, to: &tempLog)
            logString += tempLog
        }
        logString = infoString + (infoString.isEmpty ? "" : " => ") + logString
        self.printToFile(level, log: logString)
        self.xt_print(logString)
        return logString + "\n"
    }
}

extension Loger {
    @discardableResult public func info(function: String = #function,
                                        file: String = #file,
                                        line: Int = #line,
                                        _ value: Any...,
                                        separator: String = " ") -> String {
        return self.log(.info, function: function, file: file, line: line, value: value, separator: separator)
    }

    @discardableResult public func debug(function: String = #function,
                                         file: String = #file,
                                         line: Int = #line,
                                         _ value: Any...,
                                         separator: String = " ") -> String {
        return self.log(.debug, function: function, file: file, line: line, value: value, separator: separator)
    }

    @discardableResult public func warning(function: String = #function,
                                           file: String = #file,
                                           line: Int = #line,
                                           _ value: Any...,
                                           separator: String = " ") -> String {
        return self.log(.warning, function: function, file: file, line: line, value: value, separator: separator)
    }

    @discardableResult public func error(function: String = #function,
                                         file: String = #file,
                                         line: Int = #line,
                                         _ value: Any...,
                                         separator: String = " ") -> String {
        return self.log(.error, function: function, file: file, line: line, value: value, separator: separator)
    }
}

fileprivate let selfLoger = Loger()
extension Loger {
    static var `default`: Loger = selfLoger
    @discardableResult public static func info(function: String = #function,
                                               file: String = #file,
                                               line: Int = #line,
                                               _ value: Any...,
                                               separator: String = " ") -> String {
        return selfLoger.log(.info, function: function, file: file, line: line, value: value, separator: separator)
    }

    @discardableResult public static func debug(function: String = #function,
                                                file: String = #file,
                                                line: Int = #line,
                                                _ value: Any...,
                                                separator: String = " ") -> String {
        return selfLoger.log(.debug, function: function, file: file, line: line, value: value, separator: separator)
    }

    @discardableResult public static func warning(function: String = #function,
                                                  file: String = #file,
                                                  line: Int = #line,
                                                  _ value: Any...,
                                                  separator: String = " ") -> String {
        return selfLoger.log(.warning, function: function, file: file, line: line, value: value, separator: separator)
    }

    @discardableResult public static func error(function: String = #function,
                                                file: String = #file,
                                                line: Int = #line,
                                                _ value: Any...,
                                                separator: String = " ") -> String {
        return selfLoger.log(.error, function: function, file: file, line: line, value: value, separator: separator)
    }
}
