import Disposable

extension Emitter {
  public func onMainActor() -> some Emitter<Value, Failure> {
    redirect { event, downstream in
      Task { @MainActor in
        downstream(event)
      }
    }
  }
}
