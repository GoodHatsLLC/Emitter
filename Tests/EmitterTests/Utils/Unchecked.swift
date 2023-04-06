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
