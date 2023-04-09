public protocol Subject {
  associatedtype Input
  associatedtype Failure: Error
  nonisolated func fail(_ error: Failure)
  nonisolated func emit(value: Input)
  nonisolated func finish()
}
