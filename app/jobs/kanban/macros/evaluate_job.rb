class Kanban::Macros::EvaluateJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(event_type:, payload:)
    event = Kanban::Macros::Event.new(type: event_type.to_sym, payload: payload)
    Kanban::Macros::Engine.new(event).evaluate
  end
end
