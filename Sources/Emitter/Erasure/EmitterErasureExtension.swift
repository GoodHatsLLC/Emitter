import EmitterInterface

extension Emitter {

    public func erase() -> AnyEmitter<Output> {
        AnyEmitter(self)
    }
}
