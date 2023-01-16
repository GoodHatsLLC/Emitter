// MARK: - UnionType

public enum UnionType {}

// MARK: implementation
extension UnionType {

  public typealias Unionable = Hashable & Sendable

  public enum Of1<A: Unionable>: Unionable {
    case a(A)
  }

  public enum Of2<A: Unionable, B: Unionable>: Unionable {
    case a(A)
    case b(B)
  }

  public enum Of3<A: Unionable, B: Unionable, C: Unionable>: Unionable {
    case a(A)
    case b(B)
    case c(C)
  }

}
