import Disposable

extension Emitting {
  public func map<NewOutput: Sendable>(
    _ transformer: @escaping @Sendable (Output) -> NewOutput
  ) -> some Emitting<NewOutput> {
    Emitter.Map(upstream: self, transformer: transformer)
  }
}

// MARK: - Emitter.Map

extension Emitter {
  // MARK: - Map

  public struct Map<Upstream: Emitting, Output: Sendable>: Emitting {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      transformer: @escaping @Sendable (Upstream.Output) -> Output
    ) {
      self.transformer = transformer
      self.upstream = upstream
    }

    // MARK: Public

    public let transformer: @Sendable (Upstream.Output) -> Output
    public let upstream: Upstream

    public func subscribe<S: Subscriber>(_ subscriber: S) -> AnyDisposable
      where S.Value == Output
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
      where Downstream.Value == Output
    {

      fileprivate init(
        downstream: Downstream,
        transformer: @escaping (Upstream.Output) -> Output
      ) {
        self.downstream = downstream
        self.transformer = transformer
      }

      fileprivate func receive(emission: Emission<Upstream.Output>) {
        let newEmission: Emission<Output>
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
      private let transformer: (Upstream.Output)
        -> Output

    }

  }
}
