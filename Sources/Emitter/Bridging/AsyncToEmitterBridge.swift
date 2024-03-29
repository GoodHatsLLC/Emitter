
extension Emitters {
  public static func bridge<Seq: AsyncSequence>(_ sequence: Seq)
    -> some Emitter<Seq.Element, Error>
  {
    AsyncToEmitterBridge(sequence)
  }
}

// MARK: - AsyncToEmitterBridge

public struct AsyncToEmitterBridge<Seq: AsyncSequence>: Emitter, @unchecked Sendable {

  // MARK: Lifecycle

  public init(_ sequence: Seq) where Output == Seq.Element {
    self.seq = sequence
  }

  // MARK: Public

  public typealias Failure = Error

  public typealias Output = Seq.Element

  public func subscribe<S: Subscriber>(_ subscriber: S) -> AutoDisposable
    where Seq.Element == S.Input, S.Failure == any Error
  {
    let stage = DisposableStage()
    Emitters
      .create(Emission<Output, any Error>.self) { emit in
        ErasedDisposable(Task {
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
    return stage.auto()
  }

  // MARK: Private

  private let seq: Seq

}
