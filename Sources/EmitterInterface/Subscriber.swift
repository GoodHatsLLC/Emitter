public protocol Subscriber<Value> {
  associatedtype Value: Sendable
  nonisolated func receive(emission: Emission<Value>)
}
