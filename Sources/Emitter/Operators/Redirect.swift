import Disposable

extension Emitter {
  func redirect(
    _ redirection: @escaping @Sendable (
      _ event: Emission<Value, Failure>,
      _ downstream: @escaping @Sendable (Emission<Value, Failure>) -> Void
    ) -> Void
  ) -> some Emitter<Value, Failure> {
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
        _ event: Emission<Value, Failure>,
        _ downstream: @escaping @Sendable (Emission<Value, Failure>) -> Void
      ) -> Void,
      upstream: Upstream
    ) {
      self.upstream = upstream
      self.redirection = redirection
    }

    // MARK: Internal

    typealias Value = Upstream.Value
    typealias Failure = Upstream.Failure

    let upstream: Upstream

    func subscribe<S: Subscriber>(_ subscriber: S) -> AutoDisposable
      where S.Input == Value, S.Failure == Failure
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
      where Downstream.Input == Value, Downstream.Failure == Failure
    {

      fileprivate init(
        redirection: @escaping @Sendable (
          _ event: Emission<Value, Failure>,
          _ downstream: @escaping @Sendable (Emission<Value, Failure>) -> Void
        ) -> Void,
        downstream: Downstream
      ) {
        self.downstream = downstream
        self.redirection = redirection
      }

      fileprivate func receive(emission: Emission<Upstream.Value, Upstream.Failure>) {
        redirection(emission) { downstream.receive(emission: $0) }
      }

      private let downstream: Downstream
      private let redirection: @Sendable (
        _ event: Emission<Value, Failure>,
        _ downstream: @escaping @Sendable (Emission<Value, Failure>) -> Void
      ) -> Void

    }

    private let redirection: @Sendable (
      _ event: Emission<Value, Failure>,
      _ downstream: @escaping @Sendable (Emission<Value, Failure>) -> Void
    ) -> Void

  }
}
