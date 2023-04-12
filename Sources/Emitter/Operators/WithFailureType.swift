import Disposable

extension Emitter {
  public func withFailure<T: Error>(type _: T.Type) -> some Emitter<Value, T> where Failure == Never {
    Emitters.WithFailureType(upstream: self, type: T.self)
  }
}

// MARK: - Emitters.WithFailureType

extension Emitters {
  // MARK: - Prefix

  public struct WithFailureType<Upstream: Emitter, T: Error>: Emitter where Upstream.Failure == Never {

    public typealias Value = Upstream.Value
    public typealias Failure = T

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      type _: T.Type
    ) {
      self.upstream = upstream
    }

    // MARK: Public

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Input == Value, S.Failure == T
    {
      upstream.subscribe(Sub(downstream: subscriber))
    }

    private struct Sub<Downstream: Subscriber>: Subscriber
    where Downstream.Input == Upstream.Value, Downstream.Failure == T
    {

      let downstream: Downstream

      fileprivate func receive(emission: Emission<Value, Never>) {
        let newEmission: Emission<Value, T>
        switch emission {
        case .value(let value):
          newEmission = .value(value)
        case .finished:
          newEmission = .finished
        }
        downstream.receive(emission: newEmission)
      }

      typealias Value = Upstream.Value
      typealias Failure = Never

    }

    private let upstream: Upstream
  }
}
