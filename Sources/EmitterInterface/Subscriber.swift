import Foundation

@MainActor
public protocol Subscriber<Value> {
    associatedtype Value: Sendable
    func receive(emission: Emission<Value>)
}
