import Disposable

extension Emitter {
  public func mapFailure<TransformedFailure: Error>(
    _ transformer: @escaping @Sendable (_ error: Failure) -> TransformedFailure
  ) -> some Emitter<Output, TransformedFailure> {
    Emitters.MapFailure(upstream: self, transformer: transformer)
  }
}

// MARK: - Emitters.MapFailure

extension Emitters {
  // MARK: - MapFailure

  public struct MapFailure<Upstream: Emitter, TransformedFailure: Error>: Emitter {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      transformer: @escaping @Sendable (Upstream.Failure) -> TransformedFailure
    ) {
      self.transformer = transformer
      self.upstream = upstream
    }

    // MARK: Public

    public typealias Output = Upstream.Output
    public typealias Failure = TransformedFailure

    public let transformer: @Sendable (Upstream.Failure) -> TransformedFailure
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
      where Downstream.Input == Output, Downstream.Failure == TransformedFailure
    {

      typealias Output = Upstream.Output
      typealias Failure = Upstream.Failure

      fileprivate init(
        downstream: Downstream,
        transformer: @escaping (Upstream.Failure) -> TransformedFailure
      ) {
        self.downstream = downstream
        self.transformer = transformer
      }

      fileprivate func receive(emission: Emission<Output, Failure>) {
        switch emission {
        case .failed(let error):
          downstream.receive(emission: .failed(transformer(error)))
        case .finished:
          downstream.receive(emission: .finished)
        case .value(let output):
          downstream.receive(emission: .value(output))
        }
      }

      private let downstream: Downstream
      private let transformer: (Upstream.Failure) -> TransformedFailure

    }

  }
}
