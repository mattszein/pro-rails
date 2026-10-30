# Base class for expected business-rule failures raised by models (invalid state transitions, etc.).
# Controllers rescue it via TransitionErrors and render the message to the user; anything that is
# not a DomainError is a bug and must keep raising.
class DomainError < StandardError; end
