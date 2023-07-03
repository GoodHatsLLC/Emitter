import Disposable
import Foundation

extension Emitter {

  @available(macOS 13.0, iOS 16.0, *)
  public func shared(replay: Int = 1) -> some Emitter<Output, Failure> {
    Emitters.Shared(upstream: self, replayCount: replay)
  }
}

// MARK: - Emitters.Shared

extension Emitters {

  // MARK: - Prefix

  @available(macOS 13.0, iOS 16.0, *)
  public struct Shared<Upstream: Emitter>: Emitter {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      replayCount: Int
    ) {
      self.upstream = upstream
      self.replayCount = replayCount
    }

    // MARK: Public

    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure

    public func subscribe(_ subscriber: some Subscriber<Output, Failure>)
      -> AutoDisposable
    {
      if let sub = sharedSub.value {
        return sub.addSubscriber(subscriber)
      } else {
        let sub = SharedSub<Output, Failure>(
          replayCount: replayCount
        ) {
          sharedSub.value = nil
        }
        sharedSub.value = sub
        let disposable = upstream.subscribe(sub)
        sub.storeUpstream(disposable: disposable)
        return sub.addSubscriber(subscriber)
      }
    }

    // MARK: Private

    private struct SharedSub<Input, Failure: Error>: Subscriber {

      // MARK: Lifecycle

      public init(
        replayCount: Int,
        onAllUnsubscribe: @escaping () -> Void
      ) {
        self.onAllUnsubscribe = onAllUnsubscribe
        self.maxCount = replayCount
        self.cache = .init((
          buffer: ContiguousArray<Emission<Upstream.Output, Failure>>(
            unsafeUninitializedCapacity: replayCount,
            initializingWith: { _, initializedCount in
              initializedCount = 0
            }
          ),
          next: 0,
          count: 0,
          isActive: true
        ))
      }

      // MARK: Public

      public func receive(emission: Emission<Upstream.Output, Failure>) {
        switch emission {
        case .failed,
             .finished:
          cache.value.isActive = false
          return
        case .value:
          cache.withLock { mutValue in
            var (buffer, next, count, isActive) = mutValue
            assert(isActive)
            if next >= count {
              buffer.append(emission)
            } else {
              buffer[next] = emission
            }
            count = min(count + 1, maxCount)
            next = (next + 1) % maxCount
            mutValue = (buffer, next, count, isActive)
          }
          for downstream in downstreams.value.values {
            downstream.receive(emission: emission)
          }
        }
      }

      // MARK: Internal

      func storeUpstream(disposable: AutoDisposable) {
        upstreamDisposable.withLock { mutValue in
          assert(mutValue == nil)
          mutValue = disposable
        }
      }

      func getBuffer() -> [Emission<Upstream.Output, Failure>]? {
        cache.withLock { mutValue in
          let (buffer, next, count, isActive) = mutValue
          if !isActive {
            return nil
          }
          let mod = (next - count) % maxCount
          let firstStart = mod < 0 ? maxCount + mod : mod
          let firstEnd = min(firstStart + count, maxCount)
          let firstRange = firstStart ..< firstEnd
          let secondRange: Range<Int>
          if firstRange.count < count {
            let remainder = count - firstRange.count
            secondRange = 0 ..< remainder
          } else {
            secondRange = 0 ..< 0
          }
          return Array(buffer[firstRange] + buffer[secondRange])
        }
      }

      func addSubscriber(_ subscriber: some Subscriber<Output, Failure>) -> AutoDisposable {
        let id = UUID()
        let subscriber = subscriber.eraseSubscriber()
        // if we get a nil buffer, we've completed.
        guard let buffer = getBuffer()
        else {
          return AutoDisposable { }
        }
        defer {
          for output in buffer {
            subscriber.receive(emission: output)
          }
        }
        downstreams.withLock { mutValue in
          mutValue[id] = subscriber
        }
        return AutoDisposable {
          removeSubscriber(id: id)
        }
      }

      // MARK: Private

      private let onAllUnsubscribe: () -> Void

      private let maxCount: Int
      // FIXME: these separated locked state bits probably race.
      private let cache: Locked<(
        buffer: ContiguousArray<Emission<Upstream.Output, Failure>>,
        next: Int,
        count: Int,
        isActive: Bool
      )>
      private let downstreams = Locked<[UUID: AnySubscriber<Output, Failure>]>([:])
      private let upstreamDisposable = Locked<AutoDisposable?>(nil)

      private func removeSubscriber(id: UUID) {
        let remainingSubscribers = downstreams.withLock { mutValue in
          mutValue[id] = nil
          return mutValue.count
        }
        if remainingSubscribers > 0 {
          return
        }
        if
          let disposable = upstreamDisposable.withLock(action: { mutValue in
            let value = mutValue
            mutValue = nil
            return value
          })
        {
          disposable.dispose()
        }
        onAllUnsubscribe()
      }

    }

    private let sharedSub = Locked<SharedSub<Output, Failure>?>(nil)

    private let upstream: Upstream
    private let replayCount: Int
  }
}

// MARK: - Emitters.Shared + Sendable

@available(macOS 13.0, iOS 16.0, *)
extension Emitters.Shared: Sendable where Upstream: Sendable { }
