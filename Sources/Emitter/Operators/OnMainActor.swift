import Disposable

extension Emitting {
  public func onMainActor() -> some Emitting<Output> {
    redirect { event, downstream in
      Task { @MainActor in
        downstream(event)
      }
    }
  }
}
