public protocol Subject {
  associatedtype Input: Sendable
  nonisolated func emit(_ emission: Emission<Input>)
}
