import Disposable
import Foundation

extension Emitter where Failure == Never {

  public nonisolated func subscribe(
    value: @escaping (_ value: Output) -> Void,
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
    value: @escaping (_ value: Output) -> Void,
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

private struct Subscribe<Output, Failure: Error>: Subscriber {

  // MARK: Lifecycle

  fileprivate init(
    value: @escaping (Output) -> Void,
    finished: (() -> Void)?,
    failed: ((Failure) -> Void)?
  ) {
    self.valueFunc = value
    self.finishedFunc = finished
    self.failedFunc = failed
  }

  // MARK: Fileprivate

  fileprivate func receive(emission: Emission<Output, Failure>) {
    switch emission {
    case .value(let value):
      if state.value {
        valueFunc(value)
      }
    case .failed(let error):
      if
        state.withLock(action: { mutValue in
          guard mutValue
          else {
            return false
          }
          mutValue = false
          return true
        })
      {
        failedFunc?(error)
      }
    case .finished:
      if
        state.withLock(action: { mutValue in
          guard mutValue
          else {
            return false
          }
          mutValue = false
          return true
        })
      {
        finishedFunc?()
      }
    }
  }

  // MARK: Private

  private let state = Locked(true)

  private let valueFunc: (Output) -> Void
  private let finishedFunc: (() -> Void)?
  private let failedFunc: ((Failure) -> Void)?

}

// MARK: - DriverSubscribe

private struct DriverSubscribe<Output>: Subscriber {

  // MARK: Lifecycle

  fileprivate init(
    value: @escaping (Output) -> Void,
    finished: (() -> Void)?
  ) {
    self.valueFunc = value
    self.finishedFunc = finished
  }

  // MARK: Fileprivate

  fileprivate func receive(emission: Emission<Output, Never>) {
    switch emission {
    case .value(let value):
      if state.value {
        valueFunc(value)
      }
    case .finished:
      if
        state.withLock(action: { mutValue in
          guard mutValue
          else {
            return false
          }
          mutValue = false
          return true
        })
      {
        finishedFunc?()
      }
    }
  }

  // MARK: Private

  private let state = Locked(true)
  private let valueFunc: (Output) -> Void
  private let finishedFunc: (() -> Void)?

}
