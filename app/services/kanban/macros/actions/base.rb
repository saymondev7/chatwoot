class Kanban::Macros::Actions::Base
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

  def execute(card:, event:, macro:)
    raise NotImplementedError
  end
end
