import Disposable

extension Emitter {
  public func map<TransformedOutput>(
    _ transformer: @escaping @Sendable (Output) -> TransformedOutput
  ) -> some Emitter<TransformedOutput, Failure> {
    Emitters.Map(upstream: self, transformer: transformer)
  }
}

// MARK: - Emitters.Map

extension Emitters {
  // MARK: - Map

  public struct Map<Upstream: Emitter, TransformedOutput>: Emitter {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      transformer: @escaping @Sendable (Upstream.Output) -> TransformedOutput
    ) {
      self.transformer = transformer
      self.upstream = upstream
    }

    // MARK: Public

    public typealias Output = TransformedOutput
    public typealias Failure = Upstream.Failure

    public let transformer: @Sendable (Upstream.Output) -> Output
    public let upstream: Upstream

    public func subscribe<S: Subscriber>(_ subscriber: S) -> AutoDisposable
      where S.Input == Output, S.Failure == Failure
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
      where Downstream.Input == TransformedOutput, Downstream.Failure == Upstream.Failure
    {

      typealias Output = Upstream.Output
      typealias Failure = Upstream.Failure

      fileprivate init(
        downstream: Downstream,
        transformer: @escaping (Upstream.Output) -> TransformedOutput
      ) {
        self.downstream = downstream
        self.transformer = transformer
      }

      fileprivate func receive(emission: Emission<Output, Failure>) {
        let newEmission: Emission<TransformedOutput, Failure>
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
      private let transformer: (Upstream.Output) -> TransformedOutput

    }

  }
}
