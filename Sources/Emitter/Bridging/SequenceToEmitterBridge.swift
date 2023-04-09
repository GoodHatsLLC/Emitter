extension Emitters {
  public static func bridge<Seq: Sequence>(_ sequence: Seq) -> some Emitter<Seq.Element, Never> {
    Emitters.create(Emission<Seq.Element, Never>.self) { emit in
      for i in sequence {
        emit(.value(i))
      }
      emit(.finished)
    }
  }
}
