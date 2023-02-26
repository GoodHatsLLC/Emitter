public enum Emission<Value: Sendable>: Sendable {
  case value(Value)
  case finished
  case failed(Error)
}
