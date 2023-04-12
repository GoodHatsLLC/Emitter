import Disposable

extension Emitter {
  public func withPrefix(_ prefix: Output...) -> some Emitter<Output, Failure> {
    Emitters.WithPrefix(upstream: self, prefixValues: prefix)
  }

  public func withPrefix(_ prefix: [Output]) -> some Emitter<Output, Failure> {
    Emitters.WithPrefix(upstream: self, prefixValues: prefix)
  }
}

// MARK: - Emitters.WithPrefix

extension Emitters {
  // MARK: - Prefix

  public struct WithPrefix<Upstream: Emitter>: Emitter {

    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      prefixValues: [Output]
    ) {
      self.upstream = upstream
      self.prefixValues = prefixValues
    }

    // MARK: Public

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Input == Output, S.Failure == Failure
    {
      for value in prefixValues {
        subscriber.receive(emission: .value(value))
      }
      return upstream.subscribe(subscriber)
    }

    private let upstream: Upstream
    private let prefixValues: [Output]
  }
}
