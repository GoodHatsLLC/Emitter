import Disposable

extension Emitting {
  public func compactMap<NewOutput: Sendable>(
    transformer: @escaping @Sendable (Output) -> NewOutput?
  ) -> some Emitting<NewOutput> {
    Emitter.CompactMap<Self, NewOutput>(upstream: self, transformer: transformer)
  }
}

// MARK: - Emitter.CompactMap

extension Emitter {
  // MARK: - CompactMap

  public struct CompactMap<Upstream: Emitting, Output: Sendable>: Emitting {

    // MARK: Lifecycle

    init(
      upstream: Upstream,
      transformer: @escaping @Sendable (Upstream.Output) -> Output?
    ) {
      self.transformer = transformer
      self.upstream = upstream
    }

    // MARK: Public

    public let transformer: @Sendable (Upstream.Output) -> Output?
    public let upstream: Upstream

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AnyDisposable
      where S.Value == Output
    {
      upstream.subscribe(Sub<S>(downstream: subscriber, transformer: transformer))
    }

    // MARK: Private

    private struct Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Value == Output
    {
      fileprivate init(
        downstream: Downstream,
        transformer: @escaping (Upstream.Output) -> Output?
      ) {
        self.downstream = downstream
        self.transformer = transformer
      }

      fileprivate func receive(emission: Emission<Upstream.Output>) {
        let newEmission: Emission<Output>
        switch emission {
        case .value(let value):
          guard let value = transformer(value)
          else {
            return
          }
          newEmission = .value(value)
        case .finished:
          newEmission = .finished
        case .failed(let error):
          newEmission = .failed(error)
        }
        downstream.receive(emission: newEmission)
      }

      private let downstream: Downstream
      private let transformer: (Upstream.Output) -> Output?

    }

  }
}
