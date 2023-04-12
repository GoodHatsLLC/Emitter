import Disposable

extension Emitter {
  public func compact<Unwrapped: Sendable>() -> some Emitter<Unwrapped, Failure>
    where Self.Value == Unwrapped?
  {
    Emitters.Compact<Self, Unwrapped>(upstream: self)
  }

  public func compactMap<T>(
    transformer: @escaping @Sendable (Value) -> T?
  ) -> some Emitter<T, Failure> {
    map(transformer)
      .compact()
  }
}

// MARK: - Emitters.Compact

extension Emitters {
  // MARK: - CompactMap

  public struct Compact<Upstream: Emitter, Unwrapped>: Emitter where Upstream.Value == Unwrapped? {

    // MARK: Lifecycle

    init(
      upstream: Upstream
    ) {
      self.upstream = upstream
    }

    // MARK: Public

    public typealias Value = Unwrapped
    public typealias Failure = Upstream.Failure

    public let upstream: Upstream

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Failure == Failure, S.Input == Unwrapped
    {
      upstream.subscribe(Sub<S>(downstream: subscriber))
    }

    // MARK: Private

    private struct Sub<Downstream: Subscriber>: Subscriber where  Downstream.Input == Unwrapped,
      Downstream.Failure == Failure
    {

      typealias Value = Upstream.Value
      typealias Failure = Upstream.Failure

      fileprivate init(
        downstream: Downstream
      ) {
        self.downstream = downstream
      }

      fileprivate func receive(emission: Emission<Value, Failure>) {
        switch emission {
        case .value(let value):
          if let value {
            downstream.receive(emission: .value(value))
          }
        case .finished:
          downstream.receive(emission: .finished)
        case .failed(let error):
          downstream.receive(emission: .failed(error))
        }
      }

      private let downstream: Downstream

    }

  }
}
