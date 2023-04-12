struct EmissionDataProxy<Metadata: Sendable, UpstreamValue, UpstreamFailure: Error, Downstream: Subscriber>: Subscriber
where Downstream.Input == EmissionData<Metadata, UpstreamValue, UpstreamFailure>, Downstream.Failure == Never {

  typealias Input = UpstreamValue
  typealias Failure = UpstreamFailure

  init(
    metadata: Metadata,
    downstream: Downstream
  ) {
    self.metadata = metadata
    self.downstream = downstream
  }

  func receive(emission: Emission<UpstreamValue, UpstreamFailure>) {
    switch emission {
    case .value(let output):
      downstream.receive(emission: .value(.init(meta: metadata, emission: .value(output))))
    case .finished:
      downstream.receive(emission: .value(.init(meta: metadata, emission: .finished)))
    case .failed(let failure):
      downstream.receive(emission: .value(.init(meta: metadata, emission: .failure(failure))))
    }
  }

  private let metadata: Metadata
  private let downstream: Downstream
}

struct EmissionData<Metadata: Sendable, Value, Failure: Error> {
  enum Emission {
    case value(Value)
    case failure(Failure)
    case finished
  }
  let meta: Metadata
  let emission: Emission
}
