extension Emitter {
  public static func bridge<Seq: Sequence>(_ sequence: Seq) -> some Emitting<Seq.Element> {
    Emitter.create(Seq.Element.self) { emit in
      for i in sequence {
        emit(.value(i))
      }
      emit(.finished)
    }
  }
}
