class Kanban::Macros::Engine
  def initialize(event)
    @event = event
  end

  def evaluate
    account = resolve_account
    return unless account

    card = resolve_card
    return unless card

    applicable_macros(account).each do |macro|
      next unless trigger_matches?(macro)
      next unless conditions_match?(macro, card)

      execute_actions(macro, card)
    end
  end

  private

  def resolve_account
    @event.conversation&.account || @event.card&.account
  end

  def resolve_card
    return @event.card if @event.payload[:card_id]

    conv_id = @event.payload[:conversation_id]
    return nil unless conv_id

    KanbanCard.find_by(conversation_id: conv_id)
  end

  def applicable_macros(account)
    @applicable_macros ||= Kanban::Macro.where(account: account).enabled.ordered.to_a
  end

  def trigger_matches?(macro)
    macro.trigger_objects.any? { |t| t.matches?(@event) }
  end

  def conditions_match?(macro, card)
    macro.condition_objects.all? { |c| c.matches?(card: card, event: @event) }
  end

  def execute_actions(macro, card)
    ActiveRecord::Base.transaction do
      macro.action_objects.each do |action|
        action.execute(card: card, event: @event, macro: macro)
      end
    end
  rescue StandardError => e
    Rails.logger.error("[Kanban::Macros] macro #{macro.id} failed: #{e.class}: #{e.message}")
    Sentry.capture_exception(e) if defined?(Sentry)
  end
end
