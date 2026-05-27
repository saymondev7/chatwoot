class Kanban::Macros::Conditions::CardNotInColumnFunction < Kanban::Macros::Conditions::Base
  def self.key
    'card_not_in_column_function'
  end

  def self.label
    'Card NÃO está em coluna com função X'
  end

  def self.config_schema
    { column_function: { type: 'enum', values: %w[auto_receive auto_active] } }
  end

  def matches?(card:, event:) # rubocop:disable Lint/UnusedMethodArgument
    return false unless card

    card.kanban_column.column_function != config[:column_function]
  end
end
