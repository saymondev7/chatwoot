class Kanban::Macros::Triggers::LeadMessageReceived < Kanban::Macros::Triggers::Base
  def self.key
    'lead_message_received'
  end

  def self.label
    'Mensagem recebida do lead'
  end

  def self.config_schema
    {}
  end

  def matches?(event)
    return false unless event.type == :message_created

    message = event.message
    return false unless message
    return false unless message.incoming?

    # Only fire when the card is currently in the auto_active column.
    # Cards in status columns (no_function), auto_won, or auto_lost are intentionally stable.
    card = card_for(event)
    return false unless card

    card.kanban_column&.auto_active?
  end
end
