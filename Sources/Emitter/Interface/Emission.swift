// MARK: - Emission

public enum Emission<Value, Failure: Error> {
  case value(Value)
  case finished
  case failed(Failure)
}

// MARK: Sendable

extension Emission: Sendable where Value: Sendable, Failure: Sendable { }
