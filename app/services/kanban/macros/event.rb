class Kanban::Macros::Event
  attr_reader :type, :payload

  def initialize(type:, payload:)
    @type = type
    @payload = (payload || {}).symbolize_keys
  end

  def message
    return @message if defined?(@message)

    @message = payload[:message_id] && Message.find_by(id: payload[:message_id])
  end

  def conversation
    return @conversation if defined?(@conversation)

    @conversation = payload[:conversation_id] && Conversation.find_by(id: payload[:conversation_id])
  end

  def card
    return @card if defined?(@card)

    @card = payload[:card_id] && KanbanCard.find_by(id: payload[:card_id])
  end
end
