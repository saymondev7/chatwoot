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
end
