import Disposable

extension Emitter {
  public func replaceFailures(
    with replacement: Output
  ) -> some Emitter<Output, Never> {
    Emitters.ReplaceFailures(upstream: self, replacement: replacement)
  }
}

// MARK: - Emitters.ReplaceFailures

extension Emitters {
  // MARK: - ReplaceFailures

  public struct ReplaceFailures<Upstream: Emitter>: Emitter {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      replacement: Output
    ) {
      self.upstream = upstream
      self.replacement = replacement
    }

    // MARK: Public

    public typealias Output = Upstream.Output
    public typealias Failure = Never

    public let upstream: Upstream

    public func subscribe<S: Subscriber>(_ subscriber: S) -> AutoDisposable
      where S.Input == Output, S.Failure == Never
    {
      upstream.subscribe(
        Sub<S, Upstream.Failure>(
          downstream: subscriber,
          replacement: replacement
        )
      )
    }

    // MARK: Private

    private struct Sub<Downstream: Subscriber, Failure: Error>: Subscriber
      where Downstream.Input == Output, Downstream.Failure == Never
    {

      typealias Output = Upstream.Output
      typealias Failure = Failure

      fileprivate init(
        downstream: Downstream,
        replacement: Output
      ) {
        self.downstream = downstream
        self.replacement = replacement
      }

      fileprivate func receive(emission: Emission<Output, Failure>) {
        switch emission {
        case .failed:
          downstream.receive(emission: .value(replacement))
        case .finished:
          downstream.receive(emission: .finished)
        case .value(let output):
          downstream.receive(emission: .value(output))
        }
      }

      private let downstream: Downstream
      private let replacement: Output

    }

    private let replacement: Output

  }
}
