import Disposable

extension Emitter {
  public func flatMapLatest<NewValue>(
    producer: @escaping @Sendable (Value) -> some Emitter<NewValue, Failure>
  ) -> some Emitter<NewValue, Failure> {
    Emitters.FlatMapLatest(upstream: self, producer: producer)
  }
}

// MARK: - Emitters.FlatMapLatest

extension Emitters {
  // MARK: - FlatMapLatest

  public struct FlatMapLatest<Upstream: Emitter, NewValue>: Emitter {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      producer: @escaping @Sendable (Upstream.Value) -> some Emitter<NewValue, Failure>
    ) {
      self.producer = { producer($0).erase() }
      self.upstream = upstream
    }

    // MARK: Public

    public typealias Failure = Upstream.Failure
    public typealias Value = NewValue

    public let producer: @Sendable (Upstream.Value) -> AnyEmitter<NewValue, Failure>
    public let upstream: Upstream

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Input == NewValue, S.Failure == Failure
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
      where Downstream.Input == Value, Downstream.Failure == Upstream.Failure
    {

      // MARK: Lifecycle

      fileprivate init(
        downstream: Downstream,
        upstream: Upstream,
        producer: @escaping (Upstream.Value) -> AnyEmitter<Value, Failure>
      ) {
        self.downstream = downstream
        self.producer = producer
        self.upstream = upstream
      }

      // MARK: Fileprivate

      fileprivate func receive(emission: Emission<Upstream.Value, Failure>) {
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
        where Downstream.Failure == Upstream.Failure
      {

        typealias Value =  Downstream.Input
        typealias Failure = Downstream.Failure

        fileprivate init(
          downstream: Downstream
        ) {
          self.downstream = downstream
        }

        private let downstream: Downstream

        fileprivate func receive(emission: Emission<Value, Failure>) {
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
      private let producer: (Upstream.Value) -> AnyEmitter<Value, Failure>

      private let upstream: Upstream
      private var current: InnerSub<Downstream>?
      private var currentDisp: AutoDisposable?

    }

  }
}
