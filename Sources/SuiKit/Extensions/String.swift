//
//  String.swift
//  SuiKit
//
//  Copyright (c) 2023 OpenDive
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

extension String {
    var urlEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }

    public func toModule() throws -> SuiMoveNormalizedStructType {
        let callArguments = self.components(separatedBy: "::")
        guard callArguments.count == 3 else { throw SuiError.invalidModule(input: self) }
        return SuiMoveNormalizedStructType(
            address: try AccountAddress.fromHex(callArguments[0]),
            module: callArguments[1],
            name: callArguments[2],
            typeArguments: []
        )
    }

    public func stringToBytes(_ includeLength: Bool = true) throws -> [UInt8] {
        let length = self.count
        if length & 1 != 0 {
            throw SuiError.noData
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(includeLength ? ((length/2) + 1) : length/2)
        var index = self.startIndex
        for _ in 0..<(length/2) {
            let nextIndex = self.index(index, offsetBy: 2)
            if let b = UInt8(self[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                throw SuiError.unableToConvertToBytes
            }
            index = nextIndex
        }
        if includeLength { bytes.insert(UInt8(bytes.count), at: 0) }
        return bytes
    }

    public var hex: [UInt8] {
        return convertHex(self.unicodeScalars, i: self.unicodeScalars.startIndex, appendTo: [])
    }

    subscript(bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript(bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }

    public func isValidSuiAddress() -> Bool {
        return (self.isHex()) && (self.getHexByteLength() == 32)
    }

    private func isHex() -> Bool {
        let regex = try! NSRegularExpression(pattern: "^(0x|0X)?[a-fA-F0-9]+$")
        let range = NSRange(location: 0, length: self.utf16.count)
        let match = regex.firstMatch(in: self, options: [], range: range)

        return match != nil && self.count % 2 == 0
    }

    private func getHexByteLength() -> Int {
        if self.hasPrefix("0x") || self.hasPrefix("0X") {
            return (self.count - 2) / 2
        } else {
            return self.count / 2
        }
    }
}

fileprivate func convertHex(_ s: String.UnicodeScalarView, i: String.UnicodeScalarIndex, appendTo d: [UInt8]) -> [UInt8] {
    let skipChars = CharacterSet.whitespacesAndNewlines
    guard i != s.endIndex else { return d }
    let next1 = s.index(after: i)

    if skipChars.contains(s[i]) {
        return convertHex(s, i: next1, appendTo: d)
    } else {
        guard next1 != s.endIndex else { return d }

        let next2 = s.index(after: next1)
        let sub = String(s[i..<next2])

        guard let v = UInt8(sub, radix: 16) else { return d }
        return convertHex(s, i: next2, appendTo: d + [ v ])
    }
}
