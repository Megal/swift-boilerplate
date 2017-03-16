// Useful boilerplate swift code templates

import Foundation

// ---
// MARK: - Pipe-forward Operator
// ---

precedencegroup PipeForwardPrecedence {
	higherThan: MultiplicationPrecedence
	assignment: true
}
infix operator |> : PipeForwardPrecedence

/// Pipe-forward Operator
/// arg|>transform is equivalent to transform(arg)
public func |> <U, V>(arg: U, transform: (U) -> V ) -> V {
	return transform(arg)
}


// MARK: - Logging stuff
public struct StderrOutputStream: TextOutputStream {
	public mutating func write(_ string: String) { fputs(string, stderr) }
}
public var errStream = StderrOutputStream()

var loggingEnabled = true
func log(_ message: String) {

	if loggingEnabled {
		print(message, to: &errStream)
	}
}
func fatal(_ message: String = "Fatal error!") -> Never  { log(message); abort() }


// ---
// MARK: - Cartesian 2d
// ---
typealias Int2d = (x: Int, y: Int)
func +(a: Int2d, b: Int2d) -> Int2d { return (a.x+b.x, a.y+b.y) }
func -(a: Int2d, b: Int2d) -> Int2d { return (a.x-b.x, a.y-b.y) }

// ---
// MARK: - Graph theory
// ---
typealias Edge = (u: Int, v: Int)

// MARK: - Random helpers

/// xorshift128+ PRNG
func xorshift128plus(seed0 : UInt64, seed1 : UInt64) -> () -> UInt64 {
	var s0 = seed0
	var s1 = seed1
	if s0 == 0 && s1 == 0 {
		s1 =  1 // The state must be seeded so that it is not everywhere zero.
	}

	return {
		var x = s0
		let y = s1
		s0 = y
		x ^= x << 23
		x ^= x >> 17
		x ^= y
		x ^= y >> 26
		s1 = x
		return s0 &+ s1
	}

}

struct Random {

	let generator = xorshift128plus(seed0: 0xDEAD_177EA7_15_1_1, seed1: 0x1234_0978_ABCD_CDAA)

	func bounded(to max: UInt64) -> UInt64 {
		var u: UInt64 = 0
		let b: UInt64 = (u &- max) % max
		repeat {
			u = generator()
		} while u < b
		return u % max
	}

	/// Random value for `Int` in arbitrary closed range, uniformally distributed
	subscript(range: CountableClosedRange<Int>) -> Int {
		let bound = range.upperBound.toIntMax() - range.lowerBound.toIntMax() + 1
		let x = range.lowerBound + Int(bounded(to: UInt64(bound)))

		guard range.contains(x) else { fatal("out of range") }
		return x
	}

	/// Random value for `Double` in arbitrary closed range
	subscript(range: ClosedRange<Double>) -> Double {
		let step = (range.upperBound - range.lowerBound) / Double(UInt64.max)

		let value = range.lowerBound + step*Double(generator())
		guard range.contains(value) else { fatal("out of range") }

		return value
	}

	/// Random value for `Double` in arbitrary half-open range
	subscript(range: Range<Double>) -> Double {
		let step = (range.upperBound - range.lowerBound) / (1.0 + Double(UInt64.max))

		let value = range.lowerBound + step*Double(generator())
		guard range.contains(value) else { fatal("out of range") }

		return value
	}

}

let random = Random()

// ---
// MARK: - Array extension
// ---
extension Array  {

	/// Converts Array [a, b, c, ...] to Dictionary [0:a, 1:b, 2:c, ...]
	var indexedDictionary: [Int: Element] {
		var result: [Int: Element] = [:]
		enumerated().forEach { result[$0.offset] = $0.element }
		return result
	}
}

extension Sequence {

	func group(_ comp: (Self.Iterator.Element, Self.Iterator.Element) -> Bool) -> [[Self.Iterator.Element]] {

		var result: [[Self.Iterator.Element]] = []
		var current: [Self.Iterator.Element] = []

		for element in self {
			if current.isEmpty || comp(element, current.last!) {
				current.append(element)
			} else {
				result.append(current)
				current = [element]
			}
		}

		if !current.isEmpty {
			result.append(current)
		}

		return result
	}
}

extension MutableCollection where Indices.Iterator.Element == Index {
	/// Shuffles the contents of this collection.
	mutating func shuffle() {
		let c = count
		guard c > 1 else { return }

		for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
			let d: IndexDistance = random[0...numericCast(unshuffledCount-1)]|>numericCast
			guard d != 0 else { continue }
			let i = index(firstUnshuffled, offsetBy: d)
			swap(&self[firstUnshuffled], &self[i])
		}
	}
}

extension Sequence {
	/// Returns an array with the contents of this sequence, shuffled.
	func shuffled() -> [Iterator.Element] {
		var result = Array(self)
		result.shuffle()
		return result
	}
}


// Local Tests
if let inputFile = Bundle.main.path(forResource: "input", ofType: "txt") {
	freopen(inputFile, "r", stdin)
}
