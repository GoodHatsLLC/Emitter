import Disposable
import Foundation

extension Emitter {

  public func subscribeMain(
    value: @escaping @MainActor (_ value: Output) -> Void,
    finished: @escaping @MainActor () -> Void = {},
    failed: @escaping @MainActor (_ error: Error) -> Void = { _ in }
  )
    -> AnyDisposable
  {
    subscribe(
      SubscribeMain(
        value: value,
        finished: finished,
        failed: failed
      )
    )
  }
}

// MARK: - SubscribeMain

private struct SubscribeMain<Value>: Subscriber {

  fileprivate init(
    value: @escaping @MainActor (Value) -> Void,
    finished: (@MainActor () -> Void)?,
    failed: (@MainActor (Error) -> Void)?
  ) {
    valueFunc = value
    finishedFunc = finished
    failedFunc = failed
  }

  fileprivate func receive(emission: Emission<Value>) {
    Task { @MainActor in
      switch emission {
      case .value(let value):
        valueFunc(value)
      case .failed(let error):
        failedFunc?(error)
      case .finished:
        finishedFunc?()
      }
    }
  }

  private let valueFunc: @MainActor (Value) -> Void
  private let finishedFunc: (@MainActor () -> Void)?
  private let failedFunc: (@MainActor (Error) -> Void)?

}
