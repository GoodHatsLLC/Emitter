import Foundation

// MARK: - Unchecked

final class Unchecked<T>: @unchecked
Sendable {
  init(_ value: T) {
    self.value = value
  }

  var value: T
}

extension Task where Success == (), Failure == Error {
  static func flushHack(count: Int = 25) async {
    for _ in 0..<count {
      _ = await Task<(), Error> { try await Task<_, Never>.sleep(nanoseconds: 1 * USEC_PER_SEC) }.result
    }
  }

}
