import Disposable

extension Emitter {
  public func map<TransformedValue>(
    _ transformer: @escaping @Sendable (Value) -> TransformedValue
  ) -> some Emitter<TransformedValue, Failure> {
    Emitters.Map(upstream: self, transformer: transformer)
  }
}

// MARK: - Emitters.Map

extension Emitters {
  // MARK: - Map

  public struct Map<Upstream: Emitter, TransformedValue>: Emitter {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      transformer: @escaping @Sendable (Upstream.Value) -> TransformedValue
    ) {
      self.transformer = transformer
      self.upstream = upstream
    }

    // MARK: Public

    public typealias Value = TransformedValue
    public typealias Failure = Upstream.Failure

    public let transformer: @Sendable (Upstream.Value) -> Value
    public let upstream: Upstream

    public func subscribe<S: Subscriber>(_ subscriber: S) -> AutoDisposable
      where S.Input == Value, S.Failure == Failure
    {
      upstream.subscribe(
        Sub<S>(
          downstream: subscriber,
          transformer: transformer
        )
      )
    }

    // MARK: Private

    private struct Sub<Downstream: Subscriber>: Subscriber
      where  Downstream.Input == TransformedValue, Downstream.Failure == Upstream.Failure
    {

      typealias Value = Upstream.Value
      typealias Failure = Upstream.Failure

      fileprivate init(
        downstream: Downstream,
        transformer: @escaping (Upstream.Value) -> TransformedValue
      ) {
        self.downstream = downstream
        self.transformer = transformer
      }

      fileprivate func receive(emission: Emission<Value, Failure>) {
        let newEmission: Emission<TransformedValue, Failure>
        switch emission {
        case .value(let value):
          newEmission = .value(transformer(value))
        case .finished:
          newEmission = .finished
        case .failed(let error):
          newEmission = .failed(error)
        }
        downstream.receive(emission: newEmission)
      }

      private let downstream: Downstream
      private let transformer: (Upstream.Value) -> TransformedValue

    }

  }
}
