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

    message.incoming?
  end
end
