// MARK: - Union2

@frozen public enum Union2<A, B> {
  case a(A)
  case b(B)
}

// MARK: Sendable

extension Union2: Sendable where A: Sendable, B: Sendable { }

extension Union2: Error where A: Error, B: Error { }

// MARK: Equatable

extension Union2: Equatable where A: Equatable, B: Equatable { }

// MARK: Hashable

extension Union2: Hashable where A: Hashable, B: Hashable { }

// MARK: - Union3

@frozen public enum Union3<A, B, C> {
  case a(A)
  case b(B)
  case c(C)
}

// MARK: Sendable

extension Union3: Sendable where A: Sendable, B: Sendable, C: Sendable { }

// MARK: Equatable

extension Union3: Equatable where A: Equatable, B: Equatable, C: Equatable { }

// MARK: Hashable

extension Union3: Hashable where A: Hashable, B: Hashable, C: Hashable { }

extension Union3: Error where A: Error, B: Error, C: Error { }
