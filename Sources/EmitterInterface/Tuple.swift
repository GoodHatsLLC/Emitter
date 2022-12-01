// MARK: - Tuple

public enum Tuple {}

// MARK: Creation
extension Tuple {
    public static func create<A>(_ a: A) -> Size1<A> {
        Size1(a: a)
    }

    public static func create<A, B>(_ a: A, _ b: B) -> Size2<A, B> {
        Size2(a: a, b: b)
    }

    public static func create<A, B, C>(_ a: A, _ b: B, _ c: C) -> Size3<A, B, C> {
        Size3(a: a, b: b, c: c)
    }

}

// MARK: implementation
extension Tuple {
    public struct Size1<A> {
        public var a: A

        public var tuple: A {
            get { a }
            set {
                a = newValue
            }
        }
    }

    public struct Size2<A, B> {
        public var a: A
        public var b: B

        public var tuple: (A, B) {
            get { (a, b) }
            set {
                a = newValue.0
                b = newValue.1
            }
        }
    }

    public struct Size3<A, B, C> {
        public var a: A
        public var b: B
        public var c: C

        public var tuple: (A, B, C) {
            get { (a, b, c) }
            set {
                a = newValue.0
                b = newValue.1
                c = newValue.2
            }
        }
    }

}

// MARK: - Tuple.Size1 + Identifiable

extension Tuple.Size1: Identifiable where A: Identifiable {
    public var id: String { "\(a.id)" }
}

// MARK: - Tuple.Size2 + Identifiable

extension Tuple.Size2: Identifiable where A: Identifiable, B: Identifiable {
    // FIXME: should hash initial values first since they could contain '+'
    public var id: String { "\(a.id)+\(b.id)" }
}

// MARK: - Tuple.Size3 + Identifiable

extension Tuple.Size3: Identifiable where A: Identifiable, B: Identifiable, C: Identifiable {
    // FIXME: should hash initial values first since they could contain '+'
    public var id: String { "\(a.id)+\(b.id)+\(c.id)" }
}

// MARK: - Tuple.Size1 + Equatable

extension Tuple.Size1: Equatable where A: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.a == rhs.a
    }
}

// MARK: - Tuple.Size2 + Equatable

extension Tuple.Size2: Equatable where A: Equatable, B: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.a == rhs.a
            && lhs.b == rhs.b
    }
}

// MARK: - Tuple.Size3 + Equatable

extension Tuple.Size3: Equatable where A: Equatable, B: Equatable, C: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.a == rhs.a
            && lhs.b == rhs.b
            && lhs.c == rhs.c
    }
}

// MARK: - Tuple.Size1 + Hashable

extension Tuple.Size1: Hashable where A: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(a)
    }
}

// MARK: - Tuple.Size2 + Hashable

extension Tuple.Size2: Hashable where A: Hashable, B: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(a)
        hasher.combine(b)
    }
}

// MARK: - Tuple.Size3 + Hashable

extension Tuple.Size3: Hashable where A: Hashable, B: Hashable, C: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(a)
        hasher.combine(b)
        hasher.combine(c)
    }
}
