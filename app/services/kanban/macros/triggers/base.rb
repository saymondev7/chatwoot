class Kanban::Macros::Triggers::Base
  attr_reader :config

  def initialize(config)
    @config = (config || {}).with_indifferent_access
  end

  def self.key
    raise NotImplementedError
  end

  def self.label
    raise NotImplementedError
  end

  def self.config_schema
    {}
  end

  def self.validate_config!(_config)
    true
  end

  def matches?(_event)
    raise NotImplementedError
  end

  private

  # Resolves the KanbanCard associated with the event, mirroring Engine#resolve_card.
  # Triggers that need to guard on card state use this helper.
  def card_for(event)
    return event.card if event.payload[:card_id]

    conv_id = event.payload[:conversation_id]
    return nil unless conv_id

    KanbanCard.find_by(conversation_id: conv_id)
  end
end
