import Disposable
import Foundation

extension Emitting {

  public nonisolated func subscribe(
    value: @escaping (_ value: Output) -> Void,
    finished: @escaping () -> Void = { },
    failed: @escaping (_ error: Error) -> Void = { _ in }
  )
    -> AnyDisposable
  {
    subscribe(
      Subscribe(
        value: value,
        finished: finished,
        failed: failed
      )
    )
  }
}

// MARK: - Subscribe

private struct Subscribe<Value>: Subscriber {

  fileprivate init(
    value: @escaping (Value) -> Void,
    finished: (() -> Void)?,
    failed: ((Error) -> Void)?
  ) {
    self.valueFunc = value
    self.finishedFunc = finished
    self.failedFunc = failed
  }

  fileprivate func receive(emission: Emission<Value>) {
    switch emission {
    case .value(let value):
      valueFunc(value)
    case .failed(let error):
      failedFunc?(error)
    case .finished:
      finishedFunc?()
    }
  }

  private let valueFunc: (Value) -> Void
  private let finishedFunc: (() -> Void)?
  private let failedFunc: ((Error) -> Void)?

}
