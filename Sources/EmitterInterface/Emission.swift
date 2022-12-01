public enum Emission<Value> {
    case value(Value)
    case finished
    case failed(Error)
}
