import Disposable

extension Emitters {
  public static var failure: FailureEmitter<Error> {
    .init(failure: FailEmitterFailure())
  }

  public static func fail<T: Error>(with failure: T) -> FailureEmitter<T> {
    .init(failure: failure)
  }

}

// MARK: - FailureEmitter

public struct FailureEmitter<T: Error>: Emitter {
  public func subscribe<S>(_ subscriber: S) -> AutoDisposable where S: Subscriber,
    T == S.Failure, () == S.Input
  {
    subscriber.receive(emission: .finished)
    return AutoDisposable { }
  }

  let failure: T

  public typealias Output = ()
  public typealias Failure = T

}

// MARK: - FailEmitterFailure

private struct FailEmitterFailure: Error { }
