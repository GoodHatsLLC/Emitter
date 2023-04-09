public protocol Subscriber<Value, Failure> {
  associatedtype Value
  associatedtype Failure: Error
  nonisolated func receive(emission: Emission<Value, Failure>)
}
