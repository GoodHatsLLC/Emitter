@MainActor
public protocol Source {
    associatedtype Input: Sendable
    func emit(_ emission: Emission<Input>)
}
