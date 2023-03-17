import Foundation

// MARK: - Unchecked

final class Unchecked<T>: @unchecked
Sendable {

  // MARK: Lifecycle

  init(_ value: T) {
    self.value = value
  }

  // MARK: Internal

  var value: T
}

extension Task where Success == (), Failure == Error {
  static func flushHack(count: Int = 25) async {
    for _ in 0 ..< count {
      _ = await Task<Void, Error> { try await Task<_, Never>.sleep(nanoseconds: 1_000_000) }.result
    }
  }

}
