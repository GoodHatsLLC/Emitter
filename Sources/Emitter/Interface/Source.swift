public protocol Source {
  associatedtype Input: Sendable
  nonisolated func emit(_ emission: Emission<Input>)
}
