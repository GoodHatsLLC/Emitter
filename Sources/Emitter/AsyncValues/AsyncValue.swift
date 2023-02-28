public actor AsyncValue<T: Sendable> {

  public init() {}
  public init(_: T.Type) {}

  public var value: T {
    get async {
      if let _value {
        return _value
      } else {
        return await withCheckedContinuation { continuation in
          self.continuation = continuation
        }
      }
    }
  }

  public func setFinal(value: T) {
    guard _value == nil
    else {
      return
    }
    _value = value
    continuation?.resume(with: .success(value))
  }

  public nonisolated func resolve(_ value: T) {
    Task {
      await setFinal(value: value)
    }
  }

  private var _value: T?
  private var continuation: CheckedContinuation<T, Never>?
}
