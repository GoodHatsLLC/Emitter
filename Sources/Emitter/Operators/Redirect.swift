import Disposable

extension Emitter {
  func redirect(
    _ redirection: @escaping @Sendable (
      _ event: Emission<Output>,
      _ downstream: @escaping @Sendable (Emission<Output>) -> Void
    ) -> Void
  ) -> some Emitter<Output> {
    Emitters.Redirect(redirection: redirection, upstream: self)
  }
}

// MARK: - Emitters.Redirect

extension Emitters {
  // MARK: - SubscribeOn

  struct Redirect<Upstream: Emitter>: Emitter, Sendable {

    // MARK: Lifecycle

    init(
      redirection: @escaping @Sendable (
        _ event: Emission<Output>,
        _ downstream: @escaping @Sendable (Emission<Output>) -> Void
      ) -> Void,
      upstream: Upstream
    ) {
      self.upstream = upstream
      self.redirection = redirection
    }

    // MARK: Internal

    typealias Output = Upstream.Output

    let upstream: Upstream

    func subscribe<S: Subscriber>(_ subscriber: S) -> AutoDisposable
      where S.Value == Output
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
      where Downstream.Value == Output
    {

      fileprivate init(
        redirection: @escaping @Sendable (
          _ event: Emission<Output>,
          _ downstream: @escaping @Sendable (Emission<Output>) -> Void
        ) -> Void,
        downstream: Downstream
      ) {
        self.downstream = downstream
        self.redirection = redirection
      }

      fileprivate func receive(emission: Emission<Upstream.Output>) {
        redirection(emission) { downstream.receive(emission: $0) }
      }

      private let downstream: Downstream
      private let redirection: @Sendable (
        _ event: Emission<Output>,
        _ downstream: @escaping @Sendable (Emission<Output>) -> Void
      ) -> Void

    }

    private let redirection: @Sendable (
      _ event: Emission<Output>,
      _ downstream: @escaping @Sendable (Emission<Output>) -> Void
    ) -> Void

  }
}
