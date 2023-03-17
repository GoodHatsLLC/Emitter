import Disposable

extension Emitting {
  func redirect(
    _ redirection: @escaping @Sendable (
      _ event: Emission<Output>,
      _ downstream: @escaping @Sendable (Emission<Output>) -> Void
    ) -> Void
  ) -> some Emitting<Output> {
    Emitter.Redirect(redirection: redirection, upstream: self)
  }
}

// MARK: - Emitter.Redirect

extension Emitter {
  // MARK: - SubscribeOn

  struct Redirect<Upstream: Emitting>: Emitting, Sendable {

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

    func subscribe<S: Subscriber>(_ subscriber: S) -> AnyDisposable
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
