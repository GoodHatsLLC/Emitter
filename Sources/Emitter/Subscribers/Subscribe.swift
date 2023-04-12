import Disposable
import Foundation

extension Emitter where Failure == Never {

  public nonisolated func subscribe(
    value: @escaping (_ value: Value) -> Void,
    finished: @escaping () -> Void = { }
  )
    -> AutoDisposable
  {
    subscribe(
      DriverSubscribe(
        value: value,
        finished: finished
      )
    )
  }
}

extension Emitter {

  public nonisolated func subscribe(
    value: @escaping (_ value: Value) -> Void,
    finished: @escaping () -> Void = { },
    failed: @escaping (_ error: Failure) -> Void = { _ in }
  )
    -> AutoDisposable
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

private struct Subscribe<Value, Failure: Error>: Subscriber {

  fileprivate init(
    value: @escaping (Value) -> Void,
    finished: (() -> Void)?,
    failed: ((Failure) -> Void)?
  ) {
    self.valueFunc = value
    self.finishedFunc = finished
    self.failedFunc = failed
  }

  fileprivate func receive(emission: Emission<Value, Failure>) {
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
  private let failedFunc: ((Failure) -> Void)?

}


private struct DriverSubscribe<Value>: Subscriber {

  fileprivate init(
    value: @escaping (Value) -> Void,
    finished: (() -> Void)?
  ) {
    self.valueFunc = value
    self.finishedFunc = finished
  }

  fileprivate func receive(emission: Emission<Value, Never>) {
    switch emission {
    case .value(let value):
      valueFunc(value)
    case .finished:
      finishedFunc?()
    }
  }

  private let valueFunc: (Value) -> Void
  private let finishedFunc: (() -> Void)?

}
