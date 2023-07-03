import Disposable

extension Emitter {
  public func flatMapLatest<TransformedOutput>(
    producer: @escaping @Sendable (Output) -> some Emitter<TransformedOutput, Failure>
  ) -> some Emitter<TransformedOutput, Failure> {
    Emitters.FlatMapLatest(upstream: self, producer: producer)
  }
}

// MARK: - Emitters.FlatMapLatest

extension Emitters {
  // MARK: - FlatMapLatest

  public struct FlatMapLatest<Upstream: Emitter, TransformedOutput>: Emitter {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      producer: @escaping @Sendable (Upstream.Output) -> some Emitter<TransformedOutput, Failure>
    ) {
      self.producer = { producer($0).erase() }
      self.upstream = upstream
    }

    // MARK: Public

    public typealias Failure = Upstream.Failure
    public typealias Output = TransformedOutput

    public let producer: @Sendable (Upstream.Output) -> AnyEmitter<TransformedOutput, Failure>
    public let upstream: Upstream

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Input == TransformedOutput, S.Failure == Failure
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
      where Downstream.Input == Output, Downstream.Failure == Upstream.Failure
    {

      // MARK: Lifecycle

      fileprivate init(
        downstream: Downstream,
        upstream: Upstream,
        producer: @escaping (Upstream.Output) -> AnyEmitter<Output, Failure>
      ) {
        self.downstream = downstream
        self.producer = producer
        self.upstream = upstream
      }

      // MARK: Fileprivate

      fileprivate func receive(emission: Emission<Upstream.Output, Failure>) {
        switch emission {
        case .value(let value):
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

      private struct InnerSub<InnerDownstream: Subscriber>: Subscriber
        where Downstream.Failure == Upstream.Failure
      {

        typealias Output = InnerDownstream.Input
        typealias Failure = InnerDownstream.Failure

        fileprivate init(
          downstream: InnerDownstream
        ) {
          self.downstream = downstream
        }

        private let downstream: InnerDownstream

        fileprivate func receive(emission: Emission<Output, Failure>) {
          switch emission {
          case .value(let value):
            downstream.receive(emission: .value(value))
          case .finished:
            break
          case .failed(let error):
            downstream.receive(emission: .failed(error))
          }
        }
      }

      private let downstream: Downstream
      private let producer: (Upstream.Output) -> AnyEmitter<Output, Failure>

      private let upstream: Upstream
      private var current: InnerSub<Downstream>?
      private var currentDisp: AutoDisposable?

    }

  }
}
