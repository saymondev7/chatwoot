class Kanban::Macros::Conditions::Registry
  @registry = {}

  class << self
    def register(klass)
      @registry[klass.key] = klass
    end

    def fetch(key)
      @registry[key]
    end

    def build(key, config)
      klass = fetch(key)
      raise ArgumentError, "condition desconhecida: #{key}" unless klass

      klass.new(config || {})
    end

    def registered?(key)
      @registry.key?(key)
    end

    def all
      @registry.values
    end

    def reset!
      @registry = {}
    end
  end
end
