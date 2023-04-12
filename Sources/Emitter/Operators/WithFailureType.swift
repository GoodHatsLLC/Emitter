import Disposable

extension Emitter {
  public func withFailure<T: Error>(type _: T.Type) -> some Emitter<Output, T>
    where Failure == Never
  {
    Emitters.WithFailureType(upstream: self, type: T.self)
  }
}

// MARK: - Emitters.WithFailureType

extension Emitters {
  // MARK: - Prefix

  public struct WithFailureType<Upstream: Emitter, T: Error>: Emitter
    where Upstream.Failure == Never
  {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      type _: T.Type
    ) {
      self.upstream = upstream
    }

    // MARK: Public

    public typealias Output = Upstream.Output
    public typealias Failure = T

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Input == Output, S.Failure == T
    {
      upstream.subscribe(Sub(downstream: subscriber))
    }

    // MARK: Private

    private struct Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Input == Upstream.Output, Downstream.Failure == T
    {

      let downstream: Downstream

      fileprivate func receive(emission: Emission<Output, Never>) {
        let newEmission: Emission<Output, T>
        switch emission {
        case .value(let value):
          newEmission = .value(value)
        case .finished:
          newEmission = .finished
        }
        downstream.receive(emission: newEmission)
      }

      typealias Output = Upstream.Output
      typealias Failure = Never

    }

    private let upstream: Upstream
  }
}
