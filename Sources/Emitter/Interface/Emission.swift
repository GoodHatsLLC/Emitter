// MARK: - Emission

public enum Emission<Output, Failure: Error> {
  case value(Output)
  case finished
  case failed(Failure)
}

// MARK: Sendable

extension Emission: Sendable where Output: Sendable, Failure: Sendable { }
