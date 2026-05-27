class Kanban::Macros::Triggers::MessageReceivedFromTeam < Kanban::Macros::Triggers::Base
  def self.key
    'message_received_from_team'
  end

  def self.label
    'Mensagem enviada pelo time'
  end

  def self.config_schema
    {}
  end

  def matches?(event)
    return false unless event.type == :message_created

    message = event.message
    return false unless message
    return false unless message.outgoing?
    return false if message.private?

    # Only fire when the card is currently in the auto_receive column.
    # Cards in status columns (no_function), auto_active, auto_won, or auto_lost are not moved.
    card = card_for(event)
    return false unless card

    card.kanban_column&.auto_receive?
  end
end
