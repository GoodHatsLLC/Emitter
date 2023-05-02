import Disposable

extension Emitter {
  public func redirect(
    _ redirection: @escaping @Sendable (
      _ event: Emission<Output, Failure>,
      _ downstream: @escaping @Sendable (Emission<Output, Failure>) -> Void
    ) -> Void
  ) -> some Emitter<Output, Failure> {
    Emitters.Redirect(redirection: redirection, upstream: self)
  }
}

// MARK: - Emitters.Redirect

extension Emitters {
  // MARK: - SubscribeOn

  struct Redirect<Upstream: Emitter>: Emitter {

    // MARK: Lifecycle

    init(
      redirection: @escaping @Sendable (
        _ event: Emission<Output, Failure>,
        _ downstream: @escaping @Sendable (Emission<Output, Failure>) -> Void
      ) -> Void,
      upstream: Upstream
    ) {
      self.upstream = upstream
      self.redirection = redirection
    }

    // MARK: Internal

    typealias Output = Upstream.Output
    typealias Failure = Upstream.Failure

    let upstream: Upstream

    func subscribe<S: Subscriber>(_ subscriber: S) -> AutoDisposable
      where S.Input == Output, S.Failure == Failure
    {
      upstream.subscribe(
        Sub<S>(
          redirection: redirection,
          downstream: subscriber
        )
      )
    }

    // MARK: Private

    private struct Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Input == Output, Downstream.Failure == Failure
    {

      fileprivate init(
        redirection: @escaping @Sendable (
          _ event: Emission<Output, Failure>,
          _ downstream: @escaping @Sendable (Emission<Output, Failure>) -> Void
        ) -> Void,
        downstream: Downstream
      ) {
        self.downstream = downstream
        self.redirection = redirection
      }

      fileprivate func receive(emission: Emission<Upstream.Output, Upstream.Failure>) {
        redirection(emission) { downstream.receive(emission: $0) }
      }

      private let downstream: Downstream
      private let redirection: @Sendable (
        _ event: Emission<Output, Failure>,
        _ downstream: @escaping @Sendable (Emission<Output, Failure>) -> Void
      ) -> Void

    }

    private let redirection: @Sendable (
      _ event: Emission<Output, Failure>,
      _ downstream: @escaping @Sendable (Emission<Output, Failure>) -> Void
    ) -> Void

  }
}
