import Disposable

extension Emitter {
  public var firstValue: Output? {
    get async {
      let sub = Emitters.FirstValue(upstream: self)
      return await sub.asyncValue.value
    }
  }
}

// MARK: - Emitters.FirstValue

extension Emitters {

  public struct FirstValue<Upstream: Emitter>: Subscriber {

    // MARK: Lifecycle

    public init(
      upstream: Upstream
    ) {
      self.disposable = upstream.subscribe(self)
    }

    // MARK: Public

    public typealias Output = Upstream.Output

    public func receive(emission: Emission<Upstream.Output, Upstream.Failure>) {
      let wasFirst = isFirst.withLock { isFirst in
        if isFirst {
          isFirst.toggle()
          return true
        } else {
          return false
        }
      }
      if wasFirst {
        Task.detached {
          switch emission {
          case .value(let value):
            await asyncValue.resolve(to: value)
          default:
            await asyncValue.resolve(to: nil)
          }
        }
        disposable?.dispose()
      }
    }

    // MARK: Internal

    let asyncValue = AsyncValue<Upstream.Output?>()

    // MARK: Private

    private let isFirst = Locked<Bool>(true)

    private var disposable: AutoDisposable?
  }
}
