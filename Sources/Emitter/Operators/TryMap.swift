import Disposable

extension Emitter {
  public func map<TransformedOutput>(
    _ transformer: @escaping @Sendable (Output) throws -> TransformedOutput
  ) -> some Emitter<TransformedOutput, Error> {
    Emitters.TryMap(upstream: self, transformer: transformer)
  }
}

// MARK: - Emitters.TryMap

extension Emitters {
  // MARK: - TryMap

  public struct TryMap<Upstream: Emitter, TransformedOutput>: Emitter {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      transformer: @escaping @Sendable (_ value: Upstream.Output) throws -> TransformedOutput
    ) {
      self.transformer = transformer
      self.upstream = upstream
    }

    // MARK: Public

    public typealias Output = TransformedOutput
    public typealias Failure = Error

    public let transformer: @Sendable (Upstream.Output) throws -> Output
    public let upstream: Upstream

    public func subscribe<S: Subscriber>(_ subscriber: S) -> AutoDisposable
      where S.Input == Output, S.Failure == Error
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
      where Downstream.Input == TransformedOutput, Downstream.Failure == Error
    {

      // MARK: Lifecycle

      fileprivate init(
        downstream: Downstream,
        transformer: @escaping (Upstream.Output) throws -> TransformedOutput
      ) {
        self.downstream = downstream
        self.transformer = transformer
      }

      // MARK: Internal

      typealias Output = Upstream.Output
      typealias Failure = Upstream.Failure

      // MARK: Fileprivate

      fileprivate func receive(emission: Emission<Output, Failure>) {
        switch emission {
        case .value(let value):
          do {
            downstream.receive(emission: .value(try transformer(value)))
          } catch {
            downstream.receive(emission: .failed(error))
          }
        case .finished:
          downstream.receive(emission: .finished)
        case .failed(let error):
          downstream.receive(emission: .failed(error))
        }
      }

      // MARK: Private

      private let state = Locked(true)

      private let downstream: Downstream
      private let transformer: (Upstream.Output) throws -> TransformedOutput

    }

  }
}
