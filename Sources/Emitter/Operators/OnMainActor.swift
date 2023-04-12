import Disposable

extension Emitter {
  public func onMainActor() -> some Emitter<Output, Failure> {
    redirect { event, downstream in
      Task { @MainActor in
        downstream(event)
      }
    }
  }
}
