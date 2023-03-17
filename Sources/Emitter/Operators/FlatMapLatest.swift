import Disposable

extension Emitting {
  public func flatMapLatest<NewOutput: Sendable>(
    producer: @escaping @Sendable (Output) -> some Emitting<NewOutput>
  ) -> some Emitting<NewOutput> {
    Emitter.FlatMapLatest(upstream: self, producer: producer)
  }
}

// MARK: - Emitter.FlatMapLatest

extension Emitter {
  // MARK: - FlatMapLatest

  public struct FlatMapLatest<Upstream: Emitting, Output: Sendable>: Emitting {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      producer: @escaping @Sendable (Upstream.Output) -> some Emitting<Output>
    ) where Upstream.Output == Upstream.Output {
      self.producer = { producer($0).erase() }
      self.upstream = upstream
    }

    // MARK: Public

    public let producer: @Sendable (Upstream.Output) -> AnyEmitter<Output>
    public let upstream: Upstream

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AnyDisposable
      where S.Value == Output
    {
      upstream.subscribe(
        Sub<S>(
          downstream: subscriber,
          upstream: upstream,
          producer: producer
        )
      )
    }

    // MARK: Private

    private final class Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Value == Output
    {

      // MARK: Lifecycle

      fileprivate init(
        downstream: Downstream,
        upstream: Upstream,
        producer: @escaping (Upstream.Output) -> AnyEmitter<Output>
      ) {
        self.downstream = downstream
        self.producer = producer
        self.upstream = upstream
      }

      // MARK: Fileprivate

      fileprivate func receive(emission: Emission<Upstream.Output>) {
        switch emission {
        case .value(let value):
          current?.receive(emission: .finished)
          currentDisp?.dispose()
          let inner = InnerSub(downstream: downstream)
          current = inner
          currentDisp = producer(value).subscribe(inner)
        case .finished:
          downstream.receive(emission: .finished)
        case .failed(let error):
          downstream.receive(emission: .failed(error))
        }
      }

      // MARK: Private

      private struct InnerSub<Downstream: Subscriber>: Subscriber
        where Downstream.Value == Output
      {
        fileprivate init(
          downstream: Downstream
        ) {
          self.downstream = downstream
        }

        private let downstream: Downstream

        fileprivate func receive(emission: Emission<Output>) {
          switch emission {
          case .value(let value):
            downstream.receive(emission: .value(value))
          case .finished:
            downstream.receive(emission: .finished)
          case .failed(let error):
            downstream.receive(emission: .failed(error))
          }
        }
      }

      private let downstream: Downstream
      private let producer: (Upstream.Output) -> AnyEmitter<Output>

      private let upstream: Upstream
      private var current: InnerSub<Downstream>?
      private var currentDisp: AnyDisposable?

    }

  }
}
