class Kanban::Macros::Conditions::ConversationStatusIs < Kanban::Macros::Conditions::Base
  def self.key
    'conversation_status_is'
  end

  def self.label
    'Status da conversa é X'
  end

  def self.config_schema
    { status: { type: 'enum', values: %w[open resolved pending snoozed] } }
  end

  def matches?(card:, event:) # rubocop:disable Lint/UnusedMethodArgument
    conv = event.conversation
    return false unless conv

    conv.status == config[:status]
  end
end
