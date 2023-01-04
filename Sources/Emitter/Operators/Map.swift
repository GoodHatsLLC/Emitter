import Disposable
import EmitterInterface

extension Emitter {
  public func map<NewOutput: Sendable>(
    _ transformer: @escaping (Output) -> NewOutput
  ) -> some Emitter<NewOutput> {
    Emitters.Map(upstream: self, transformer: transformer)
  }
}

// MARK: - Emitters.Map

extension Emitters {
  // MARK: - Map

  public struct Map<Upstream: Emitter, Output: Sendable>: Emitter {

    public init(
      upstream: Upstream,
      transformer: @escaping (Upstream.Output) -> Output
    ) {
      self.transformer = transformer
      self.upstream = upstream
    }

    public let transformer: (Upstream.Output) -> Output
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
