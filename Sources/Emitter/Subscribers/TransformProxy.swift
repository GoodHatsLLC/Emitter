struct TransformProxy<UpstreamValue, UpstreamFailure: Error, Downstream: Subscriber>: Subscriber {

  typealias Output = UpstreamValue
  typealias Failure = UpstreamFailure

  init(
    downstream: Downstream,
    joinOutput: @escaping (UpstreamValue) -> Downstream.Input,
    joinFailure: @escaping (UpstreamFailure) -> Downstream.Failure
  ) {
    self.downstream = downstream
    self.joinOutput = joinOutput
    self.joinFailure = joinFailure
  }

  func receive(emission: Emission<UpstreamValue, UpstreamFailure>) {
    let forwarded: Emission<Downstream.Input, Downstream.Failure>
    switch emission {
    case .value(let value):
      forwarded = .value(joinOutput(value))
    case .finished:
      forwarded = .finished
    case .failed(let error):
      forwarded = .failed(joinFailure(error))
    }
    downstream.receive(emission: forwarded)
  }

  private let downstream: Downstream
  private let joinOutput: (UpstreamValue) -> Downstream.Input
  private let joinFailure: (UpstreamFailure) -> Downstream.Failure
}
