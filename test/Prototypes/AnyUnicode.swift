//===--- AnyUnicode.swift -------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
// RUN: %target-run-simple-swift
// REQUIRES: executable_test

import StdlibUnittest

struct UnicodeIndex : Comparable {
  var offset: Int64
  static func == (l: UnicodeIndex, r: UnicodeIndex) -> Bool {
    return l.offset == r.offset
  }
  static func < (l: UnicodeIndex, r: UnicodeIndex) -> Bool {
    return l.offset < r.offset
  }
}

protocol AnyCodeUnits_ {
  typealias IndexDistance = Int64
  typealias Index = Int64
  typealias Element = UInt32
  var startIndex: Index { get }
  var endIndex: Index { get }
  func index(after: Index) -> Index
  func index(before: Index) -> Index
  func index(_ i: Index, offsetBy: Int64) -> Index
  subscript(i: Index) -> Element { get }
  //  subscript(r: Range<Index>) -> AnyCodeUnits { get }

  func withExistingUnsafeBuffer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R?
}

struct AnyCodeUnits : RandomAccessCollection, AnyCodeUnits_ {
  typealias IndexDistance = Int64
  typealias Index = Int64
  typealias Element = UInt32
  
  let base: AnyCodeUnits_

  // FIXME: associated type deduction seems to need a hint here.
  typealias Indices = DefaultRandomAccessIndices<AnyCodeUnits>
  var startIndex: Index { return base.startIndex }
  var endIndex: Index { return base.endIndex }
  func index(after i: Index) -> Index { return base.index(after: i) }
  func index(before i: Index) -> Index { return base.index(before: i) }
  func index(_ i: Index, offsetBy: Int64) -> Index { return base.index(i, offsetBy: i) }
  subscript(i: Index) -> Element { return base[i] }
  
  public func withExistingUnsafeBuffer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? { return try base.withExistingUnsafeBuffer(body) }
}

/// Adapts any random access collection of unsigned integer to AnyCodeUnits_
struct AnyCodeUnitsZeroExtender<
  Base: RandomAccessCollection
> : RandomAccessCollection, AnyCodeUnits_
where Base.Iterator.Element : UnsignedInteger {
  typealias IndexDistance = Int64
  typealias Index = Int64
  typealias Element = UInt32
  // FIXME: associated type deduction seems to need a hint here.
  typealias Indices = DefaultRandomAccessIndices<AnyCodeUnitsZeroExtender>
  
  let base: Base

  var startIndex: Index { return 0 }
  var endIndex: Index { return numericCast(base.count) }
  
  func index(after i: Index) -> Index {
    return numericCast(
      base.offset(of: base.index(after: base.index(atOffset: i))))
  }
  
  func index(before i: Index) -> Index {
    return numericCast(
      base.offset(of: base.index(before: base.index(atOffset: i))))
  }
  
  func index(_ i: Index, offsetBy n: Int64) -> Index {
    return numericCast(
      base.offset(
        of: base.index(base.index(atOffset: i),
          offsetBy: numericCast(n))))
  }
  
  subscript(i: Index) -> Element {
    return numericCast(base[base.index(atOffset: i)])
  }

  public func withExistingUnsafeBuffer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return try base.withExistingUnsafeBuffer {
      try ($0 as Any as? UnsafeBufferPointer<Element>).map(body)
    }.flatMap { $0 }
  }
}

protocol AnyUTF16_ {
  typealias IndexDistance = Int64
  typealias Index = UnicodeIndex
  typealias Element = UInt16
  var startIndex: Index { get }
  var endIndex: Index { get }
  func index(after: Index) -> Index
  func index(before: Index) -> Index
  subscript(i: Index) -> Element { get }

  func withExistingUnsafeBuffer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R?
}

struct AnyUTF16 : BidirectionalCollection, AnyUTF16_ {
  let base: AnyUTF16_
  typealias IndexDistance = Int64
  typealias Index = UnicodeIndex
  typealias Element = UInt16
  var startIndex: Index { return base.startIndex }
  var endIndex: Index { return base.endIndex }
  func index(after i: Index) -> Index { return base.index(after: i) }
  func index(before i: Index) -> Index { return base.index(before: i) }
  subscript(i: Index) -> Element { return base[i] }
  public func withExistingUnsafeBuffer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return try base.withExistingUnsafeBuffer(body)
  }
}

/// Adapts any bidirectional collection of unsigned integer to AnyUTF16_
struct AnyUTF16ZeroExtender<
  Base: BidirectionalCollection
> : BidirectionalCollection, AnyUTF16_
where Base.Iterator.Element : UnsignedInteger {
  typealias IndexDistance = Int64
  typealias Index = UnicodeIndex
  typealias Element = UInt16
  
  let base: Base

  var startIndex: Index { return Index(offset: 0) }
  var endIndex: Index { return Index(offset: numericCast(base.count)) }
  
  func index(after i: Index) -> Index {
    return Index(offset: numericCast(
        base.offset(of: base.index(after: base.index(atOffset: i.offset)))))
  }
  
  func index(before i: Index) -> Index {
    return Index(offset: numericCast(
        base.offset(of: base.index(before: base.index(atOffset: i.offset)))))
  }
  
  func index(_ i: Index, offsetBy n: Int64) -> Index {
    return Index(offset: numericCast(
      base.offset(
        of: base.index(base.index(atOffset: i.offset),
            offsetBy: numericCast(n)))))
  }
  
  subscript(i: Index) -> Element {
    return numericCast(base[base.index(atOffset: i.offset)])
  }

  public func withExistingUnsafeBuffer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return try base.withExistingUnsafeBuffer {
      try ($0 as Any as? UnsafeBufferPointer<Element>).map(body)
    }.flatMap { $0 }
  }
}

protocol AnyUnicodeBidirectionalUInt32_ {
  typealias IndexDistance = Int64
  typealias Index = UnicodeIndex
  typealias Element = UInt32
  var startIndex: Index { get }
  var endIndex: Index { get }
  func index(after: Index) -> Index
  func index(before: Index) -> Index
  subscript(i: Index) -> Element { get }

  func withExistingUnsafeBuffer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R?
}

// Adapts any bidirectional collection of UInt32 to AnyUnicodeBidirectionalUInt32_
struct AnyUnicodeBidirectionalUInt32 : BidirectionalCollection, AnyUnicodeBidirectionalUInt32_ {
  let base: AnyUnicodeBidirectionalUInt32_
  typealias IndexDistance = Int64
  typealias Index = UnicodeIndex
  typealias Element = UInt32
  var startIndex: Index { return base.startIndex }
  var endIndex: Index { return base.endIndex }
  func index(after i: Index) -> Index { return base.index(after: i) }
  func index(before i: Index) -> Index { return base.index(before: i) }
  subscript(i: Index) -> Element { return base[i] }
  public func withExistingUnsafeBuffer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return try base.withExistingUnsafeBuffer {
      try ($0 as Any as? UnsafeBufferPointer<Element>).map(body)
    }.flatMap { $0 }
  }
}

/// Adapts any bidirectional collection of unsigned integer to AnyUnicodeBidirectionalUInt32_
struct AnyUnicodeBidirectionalUInt32ZeroExtender<
  Base: BidirectionalCollection
> : BidirectionalCollection, AnyUnicodeBidirectionalUInt32_
where Base.Iterator.Element : UnsignedInteger {
  typealias IndexDistance = Int64
  typealias Index = UnicodeIndex
  typealias Element = UInt32
  
  let base: Base

  var startIndex: Index { return Index(offset: 0) }
  var endIndex: Index { return Index(offset: numericCast(base.count)) }
  
  func index(after i: Index) -> Index {
    return Index(offset: numericCast(
        base.offset(of: base.index(after: base.index(atOffset: i.offset)))))
  }
  
  func index(before i: Index) -> Index {
    return Index(offset: numericCast(
        base.offset(of: base.index(before: base.index(atOffset: i.offset)))))
  }
  
  func index(_ i: Index, offsetBy n: Int64) -> Index {
    return Index(offset: numericCast(
      base.offset(
        of: base.index(base.index(atOffset: i.offset),
            offsetBy: numericCast(n)))))
  }
  
  subscript(i: Index) -> Element {
    return numericCast(base[base.index(atOffset: i.offset)])
  }

  public func withExistingUnsafeBuffer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return try base.withExistingUnsafeBuffer {
      try ($0 as Any as? UnsafeBufferPointer<Element>).map(body)
    }.flatMap { $0 }
  }
}

protocol AnyCharacters_ {
  typealias IndexDistance = Int64
  typealias Index = UnicodeIndex
  typealias Element = Character
  var startIndex: Index { get }
  var endIndex: Index { get }
  func index(after: Index) -> Index
  func index(before: Index) -> Index
  subscript(i: Index) -> Element { get }

  func withExistingUnsafeBuffer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R?
}

struct AnyCharacters : BidirectionalCollection, AnyCharacters_ {
  let base: AnyCharacters_
  typealias IndexDistance = Int64
  typealias Index = UnicodeIndex
  typealias Element = Character
  var startIndex: Index { return base.startIndex }
  var endIndex: Index { return base.endIndex }
  func index(after i: Index) -> Index { return base.index(after: i) }
  func index(before i: Index) -> Index { return base.index(before: i) }
  subscript(i: Index) -> Element { return base[i] }
  public func withExistingUnsafeBuffer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return try base.withExistingUnsafeBuffer {
      try ($0 as Any as? UnsafeBufferPointer<Element>).map(body)
    }.flatMap { $0 }
  }
}

protocol AnyUnicode {
  var encoding: AnyUnicodeEncoding { get }
  var codeUnits: AnyCodeUnits { get }
  var utf16: AnyUTF16 { get }
  var utf32: AnyUnicodeBidirectionalUInt32 { get }
  // FIXME: Can this be Random Access?  If all encodings use a single code unit
  // per ASCII character and can statelessly identify a code unit that
  // represents ASCII, then yes.  Look into, e.g. shift-JIS.
  var extendedASCII : AnyUnicodeBidirectionalUInt32 { get }
  var characters : AnyCharacters { get }
  
  func isASCII(scan: Bool/* = true */) -> Bool 
  func isLatin1(scan: Bool/* = true */) -> Bool 
  func isNormalizedNFC(scan: Bool/* = true*/) -> Bool
  func isNormalizedNFD(scan: Bool/* = true*/) -> Bool
  func isInFastCOrDForm(scan: Bool/* = true*/) -> Bool
}

struct AnyRandomAccessUnsignedIntegers<
  Base: RandomAccessCollection, Element_ : UnsignedInteger
> : RandomAccessCollection
where Base.Iterator.Element : UnsignedInteger {
  typealias IndexDistance = Int64
  typealias Index = Int64
  typealias Element = Element_
  // FIXME: associated type deduction seems to need a hint here.
  typealias Indices = DefaultRandomAccessIndices<AnyRandomAccessUnsignedIntegers>
  
  let base: Base

  var startIndex: Index { return 0 }
  var endIndex: Index { return numericCast(base.count) }
  
  func index(after i: Index) -> Index {
    return numericCast(
      base.offset(of: base.index(after: base.index(atOffset: i))))
  }
  
  func index(before i: Index) -> Index {
    return numericCast(
      base.offset(of: base.index(before: base.index(atOffset: i))))
  }
  
  func index(_ i: Index, offsetBy n: Int64) -> Index {
    return numericCast(
      base.offset(
        of: base.index(base.index(atOffset: i),
          offsetBy: numericCast(n))))
  }
  
  subscript(i: Index) -> Element {
    return numericCast(base[base.index(atOffset: i)])
  }

  public func withExistingUnsafeBuffer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return try base.withExistingUnsafeBuffer {
      try ($0 as Any as? UnsafeBufferPointer<Element>).map(body)
    }.flatMap { $0 }
  }
}

protocol AnyUnicodeEncoding : Swift.AnyUnicodeEncoding {
  static func utf16View<CodeUnits: RandomAccessCollection>(_: CodeUnits) -> AnyUTF16
    where CodeUnits.Iterator.Element : UnsignedInteger
}

extension AnyUnicodeEncoding
  where Self : UnicodeEncoding,
  Self.EncodedScalar.Iterator.Element : UnsignedInteger {
  
  static func utf16View<
    CodeUnits: RandomAccessCollection
  >(codeUnits: CodeUnits) -> AnyUTF16
  where CodeUnits.Iterator.Element : UnsignedInteger {
    typealias WidthAdjusted = AnyRandomAccessUnsignedIntegers<CodeUnits, CodeUnit>
    typealias Storage = UnicodeStorage<WidthAdjusted, Self>
    
    let r = Storage.TranscodedView(
      WidthAdjusted(base: codeUnits),
      from: self,
      to: UTF16.self
    )
    fatalError()
  }
}
/*
extension AnyUnicode {
  var utf16: AnyUTF16 {
    return 
  }
}
*/

var suite = TestSuite("AnyUnicode")
suite.test("basics") {
  let x = AnyUTF16ZeroExtender(base: Array(3...7) as [UInt16])
  let y = AnyUTF16ZeroExtender(base: Array(3...7) as [UInt8])
  expectTrue(x.elementsEqual(y))
}

runAllTests()
