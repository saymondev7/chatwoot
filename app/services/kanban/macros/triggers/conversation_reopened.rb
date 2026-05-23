class Kanban::Macros::Triggers::ConversationReopened < Kanban::Macros::Triggers::Base
  def self.key
    'conversation_reopened'
  end

  def self.label
    'Conversa reaberta'
  end

  def self.config_schema
    {}
  end

  def matches?(event)
    event.type == :conversation_reopened
  end
end
