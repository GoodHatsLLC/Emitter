public protocol Subscriber<Input, Failure> {
  associatedtype Input
  associatedtype Failure: Error
  nonisolated func receive(emission: Emission<Input, Failure>)
}
