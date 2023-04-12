import Disposable
import Foundation

extension Emitter {

  public nonisolated func subscribeMain(
    value: @escaping @MainActor (_ value: Output) -> Void,
    finished: @escaping @MainActor () -> Void = { },
    failed: @escaping @MainActor (_ error: Error) -> Void = { _ in }
  )
    -> AutoDisposable
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

private struct SubscribeMain<Output, Failure: Error>: Subscriber {

  fileprivate init(
    value: @escaping @MainActor (Output) -> Void,
    finished: (@MainActor () -> Void)?,
    failed: (@MainActor (Error) -> Void)?
  ) {
    self.valueFunc = value
    self.finishedFunc = finished
    self.failedFunc = failed
  }

  fileprivate func receive(emission: Emission<Output, Failure>) {
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

  private let valueFunc: @MainActor (Output) -> Void
  private let finishedFunc: (@MainActor () -> Void)?
  private let failedFunc: (@MainActor (Error) -> Void)?

}
