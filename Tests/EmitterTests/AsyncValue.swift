// MARK: - AsyncValue

public actor AsyncValue<T: Sendable> {

  // MARK: Lifecycle

  public init() { }
  public init(value: T) {
    self._value = value
  }

  // MARK: Public

  public var value: T {
    get async {
      if let _value {
        return _value
      } else {
        return await withCheckedContinuation { continuation in
          self.continuations.append(continuation)
        }
      }
    }
  }

  public func resolve(_ value: T, act: @escaping () async -> Void = { }) async {
    guard _value == nil
    else {
      return
    }
    _value = value
    await act()
    let continuations = continuations
    self.continuations.removeAll()
    for continuation in continuations {
      continuation.resume(with: .success(value))
    }
  }

  public func ifMatching(_ filter: (_ value: T?) -> Bool, run: @escaping () async -> Void) async {
    if filter(_value) {
      await run()
    }
  }

  // MARK: Private

  private var _value: T?
  private var continuations: [CheckedContinuation<T, Never>] = []

}
