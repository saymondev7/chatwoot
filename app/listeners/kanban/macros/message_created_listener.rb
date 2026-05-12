class Kanban::Macros::MessageCreatedListener < BaseListener
  def message_created(event)
    message = event.data[:message]
    return unless message
    return if message.conversation_id.blank?
    return unless message.incoming?

    Kanban::Macros::EvaluateJob.perform_later(
      event_type: 'message_created',
      payload: { message_id: message.id, conversation_id: message.conversation_id }
    )
  end
end
