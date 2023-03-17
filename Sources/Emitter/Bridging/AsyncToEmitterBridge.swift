
extension Emitter {
  public static func bridge<Seq: AsyncSequence>(_ sequence: Seq) -> some Emitting<Seq.Element> {
    AsyncToEmitterBridge(sequence)
  }
}

// MARK: - AsyncToEmitterBridge

public struct AsyncToEmitterBridge<Seq: AsyncSequence>: Emitting, @unchecked Sendable {
  public typealias Output = Seq.Element

  public func subscribe<S: Subscriber>(_ subscriber: S) -> AnyDisposable
    where Seq.Element == S.Value
  {
    let stage = DisposableStage()
    Emitter
      .create(Output.self) { emit in
        AnyDisposable(Task {
          do {
            for try await value in seq {
              emit(.value(value))
            }
            emit(.finished)
          } catch {
            emit(.failed(error))
          }
        })
        .stage(on: stage)
      }
      .subscribe(subscriber)
      .stage(on: stage)
    return stage.erase()
  }

  private let seq: Seq

  public init(_ sequence: Seq) where Output == Seq.Element {
    self.seq = sequence
  }
}
