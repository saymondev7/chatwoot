class Kanban::Macros::Conditions::MessageSenderIsLead < Kanban::Macros::Conditions::Base
  def self.key
    'message_sender_is_lead'
  end

  def self.label
    'Mensagem foi enviada pelo lead'
  end

  def self.config_schema
    {}
  end

  def matches?(card:, event:) # rubocop:disable Lint/UnusedMethodArgument
    msg = event.message
    return false unless msg

    msg.incoming? && msg.sender_type == 'Contact'
  end
end
