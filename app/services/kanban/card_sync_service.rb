class Kanban::CardSyncService
  POSITION_RETRY_LIMIT = 3

  def initialize(conversation:)
    @conversation = conversation
    @contact = conversation.contact
    @account = conversation.account
  end

  # Called when assignee changes. Moves card to the new assignee's board.
  def sync_to_assignee
    assignee = @conversation.assignee
    return if skip_assignee?(assignee)

    board = @account.kanban_boards.find_or_create_by!(user: assignee)
    receive_column = KanbanColumn.auto_receive_for(@account)
    return unless receive_column

    with_position_retry do
      card = KanbanCard.find_by(conversation_id: @conversation.id)
      if card.nil?
        create_card_for_assignee(assignee, board, receive_column)
      elsif needs_resync?(card, board)
        card.update!(
          kanban_board: board,
          kanban_column: receive_column,
          position: KanbanCard.next_position(receive_column.id, board.id)
        )
      end
    end
  end

  # Called when conversation transitions to resolved.
  # Moves card to auto_won/auto_lost column (if configured), then archives it.
  def sync_on_resolution
    card = KanbanCard.find_by(conversation_id: @conversation.id)
    return unless card

    target_function = resolution_target_function
    if target_function
      target_column = @account.kanban_columns.find_by(column_function: target_function)
      if target_column
        move_card_to_column(card, target_column)
      else
        Rails.logger.warn("[KanbanCardSyncService] No #{target_function} column for account #{@account.id}, skipping move")
      end
    end

    card.archive!
  end

  # Legacy entry point used by create callback (on assignee present).
  def sync
    sync_to_assignee if @conversation.assignee.present?
  end

  private

  def move_card_to_column(card, target_column)
    return if card.kanban_column_id == target_column.id

    from_column = card.kanban_column

    ActiveRecord::Base.transaction do
      with_position_retry do
        card.update!(
          kanban_column: target_column,
          position: KanbanCard.next_position(target_column.id, card.kanban_board_id)
        )
      end
      KanbanCardActivity.create!(
        kanban_card: card,
        from_column: from_column,
        to_column: target_column,
        user: nil,
        source: :system,
        event_type: :stage_changed,
        metadata: { trigger: 'conversation_resolved' }
      )
    end
  end

  def create_card_for_assignee(assignee, board, column)
    KanbanCard.create!(
      conversation: @conversation,
      contact: @contact,
      kanban_board: board,
      kanban_column: column,
      created_by: assignee,
      position: KanbanCard.next_position(column.id, board.id)
    )
  end

  def needs_resync?(card, target_board)
    card.kanban_board_id != target_board.id
  end

  def resolution_target_function
    classification = @conversation.classification
    return nil unless classification
    return :auto_won if classification.won?
    return :auto_lost if classification.lost?

    nil
  end

  def skip_assignee?(user)
    return true if user.blank?

    !user.kanban_enabled
  end

  def with_position_retry
    attempts = 0
    begin
      yield
    rescue ActiveRecord::RecordNotUnique
      attempts += 1
      retry if attempts < POSITION_RETRY_LIMIT
      raise
    end
  end
end
