class Kanban::Macros::Actions::MoveCardToColumnFunction < Kanban::Macros::Actions::Base
  def self.key
    'move_card_to_column_function'
  end

  def self.label
    'Mover card para coluna com função X'
  end

  def self.config_schema
    { column_function: { type: 'enum', values: %w[auto_receive auto_active], required: true } }
  end

  def self.validate_config!(config)
    raise ArgumentError, 'column_function é obrigatório' if config['column_function'].blank?

    true
  end

  def execute(card:, event:, macro:) # rubocop:disable Lint/UnusedMethodArgument
    raise 'card ausente' unless card

    target = find_target_column(card)
    return log_missing_target(card, macro) unless target
    return { skipped: 'already_in_target' } if card.kanban_column_id == target.id

    move_and_log(card, target, macro)
  end

  private

  def find_target_column(card)
    KanbanColumn.find_by(account: card.kanban_column.account, column_function: config[:column_function])
  end

  def log_missing_target(card, macro)
    Rails.logger.warn(
      "[Kanban::Macros] account #{card.kanban_column.account_id} sem coluna " \
      "#{config[:column_function]} — macro #{macro.id} ignorado"
    )
    { skipped: 'target_column_not_configured' }
  end

  def move_and_log(card, target, macro)
    from_column = card.kanban_column
    ActiveRecord::Base.transaction do
      card.update!(kanban_column: target)
      KanbanCardActivity.create!(
        kanban_card: card,
        from_column: from_column,
        to_column: target,
        user: nil,
        source: :macro,
        event_type: :stage_changed,
        metadata: { macro_id: macro.id, macro_name: macro.name }
      )
    end
    { moved: true, from: from_column.id, to: target.id }
  end
end
