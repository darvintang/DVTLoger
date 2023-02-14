//
//  MemoryTool.swift
//
//
//  Created by darvin on 2019/6/22.
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

public enum MemoryAlign: Int {
    case one = 1, two = 2, four = 4, eight = 8
}

private let _EMPTY_PTR = UnsafeRawPointer(bitPattern: 0x1)!

/// 辅助查看内存的小工具类
public struct Memory<T> {
    // MARK: Public
    /// 获得变量的内存数据（字节数组格式）
    public static func memoryBytes(ofValue value: inout T) -> [UInt8] {
        return self._memoryBytes(self.pointer(ofValue: &value), MemoryLayout.stride(ofValue: value))
    }

    /// 获得引用所指向的内存数据（字节数组格式）
    public static func memoryBytes(ofReference value: T) -> [UInt8] {
        let pointer = self.pointer(ofReference: value)
        return self._memoryBytes(pointer, malloc_size(pointer))
    }

    /// 获得变量的内存数据（字符串格式）
    ///
    /// - Parameter alignment: 决定了多少个字节为一组
    public static func memoryString(ofValue value: inout T, alignment: MemoryAlign? = nil) -> String {
        let pointer = self.pointer(ofValue: &value)
        return self._memString(pointer, MemoryLayout.stride(ofValue: value),
                               alignment != nil ? alignment!.rawValue : MemoryLayout.alignment(ofValue: value))
    }

    /// 获得引用所指向的内存数据（字符串格式）
    ///
    /// - Parameter alignment: 决定了多少个字节为一组
    public static func memoryString(ofReference value: T, alignment: MemoryAlign? = nil) -> String {
        let pointer = self.pointer(ofReference: value)
        return self._memString(pointer, malloc_size(pointer),
                               alignment != nil ? alignment!.rawValue : MemoryLayout.alignment(ofValue: value))
    }

    /// 获得变量的内存地址
    public static func pointer(ofValue value: inout T) -> UnsafeRawPointer {
        return MemoryLayout.size(ofValue: value) == 0 ? _EMPTY_PTR : withUnsafePointer(to: &value) {
            UnsafeRawPointer($0)
        }
    }

    /// 获得引用所指向内存的地址
    public static func pointer(ofReference value: T) -> UnsafeRawPointer {
        if value is [Any]
            || Swift.type(of: value) is AnyClass
            || value is AnyClass {
            return UnsafeRawPointer(bitPattern: unsafeBitCast(value, to: UInt.self))!
        } else if value is String {
            var mstr = value as! String
            if mstr.memoryType() != .heap {
                return _EMPTY_PTR
            }
            return UnsafeRawPointer(bitPattern: unsafeBitCast(value, to: (UInt, UInt).self).1)!
        } else {
            return _EMPTY_PTR
        }
    }

    /// 获得变量所占用的内存大小
    public static func size(ofValue value: inout T) -> Int {
        return MemoryLayout.size(ofValue: value) > 0 ? MemoryLayout.stride(ofValue: value) : 0
    }

    /// 获得引用所指向内存的大小
    public static func size(ofReference value: T) -> Int {
        return malloc_size(self.pointer(ofReference: value))
    }

    // MARK: Private
    private static func _memString(_ pointer: UnsafeRawPointer,
                                   _ size: Int,
                                   _ aligment: Int) -> String {
        if pointer == _EMPTY_PTR { return "" }

        var rawPtr = pointer
        var string = ""
        let fmt = "0x%0\(aligment << 1)lx"
        let count = size / aligment
        for i in 0 ..< count {
            if i > 0 {
                string.append(" ")
                rawPtr += aligment
            }
            let value: CVarArg
            switch aligment {
                case MemoryAlign.eight.rawValue:
                    value = rawPtr.load(as: UInt64.self)
                case MemoryAlign.four.rawValue:
                    value = rawPtr.load(as: UInt32.self)
                case MemoryAlign.two.rawValue:
                    value = rawPtr.load(as: UInt16.self)
                default:
                    value = rawPtr.load(as: UInt8.self)
            }
            string.append(String(format: fmt, value))
        }
        return string
    }

    private static func _memoryBytes(_ pointer: UnsafeRawPointer,
                                     _ size: Int) -> [UInt8] {
        var array: [UInt8] = []
        if pointer == _EMPTY_PTR { return array }
        for i in 0 ..< size {
            array.append((pointer + i).load(as: UInt8.self))
        }
        return array
    }
}

public enum StringMemoryType: UInt8 {
    /// TEXT段（常量区）
    case text = 0xD0
    /// taggerPointer
    case tagger = 0xE0
    /// 堆空间
    case heap = 0xF0
    /// 未知
    case unknow = 0xFF
}

public extension String {
    mutating func memoryType() -> StringMemoryType {
        let ptr = Memory.pointer(ofValue: &self)
        return StringMemoryType(rawValue: (ptr + 15).load(as: UInt8.self) & 0xF0)
            ?? StringMemoryType(rawValue: (ptr + 7).load(as: UInt8.self) & 0xF0)
            ?? .unknow
    }
}
