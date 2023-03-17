public protocol Subject {
  associatedtype Input: Sendable
  nonisolated func fail(_ error: some Error)
  nonisolated func emit(value: Input)
  nonisolated func finish()
}
