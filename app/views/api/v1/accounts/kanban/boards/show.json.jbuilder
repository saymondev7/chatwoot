json.id @board.id
json.user_id @board.user_id
json.account_id @board.account_id

board_cards_by_column = @board.cards
                              .active
                              .includes(:contact,
                                        :conversation,
                                        { activities: [:user, :from_column, :to_column] },
                                        { schedules: :created_by })
                              .group_by(&:kanban_column_id)

# Single aggregate query to avoid N+1 (1 query for all cards regardless of board size).
# Uses assignee_last_seen_at so the badge reflects what the assigned agent has read,
# not what any other agent (e.g. admin browsing) has seen.
all_conv_ids = board_cards_by_column.values.flatten.filter_map(&:conversation_id)
unread_counts = if all_conv_ids.any?
  Message
    .joins(:conversation)
    .where(conversations: { id: all_conv_ids })
    .where(message_type: 0, private: false)
    .where(
      'messages.created_at > conversations.assignee_last_seen_at OR conversations.assignee_last_seen_at IS NULL'
    )
    .reorder(nil)
    .group('conversations.id')
    .count
else
  {}
end

json.columns Current.account.kanban_columns do |column|
  raw_cards = board_cards_by_column[column.id] || []
  column_cards = raw_cards.sort_by { |c| KanbanCard.sort_keys_for_column(c, column) }
  json.id column.id
  json.name column.name
  json.position column.position
  json.color column.color
  json.column_type column.column_type
  json.column_function column.column_function
  json.cards_count column_cards.size
  json.potential_value_sum(column_cards.sum { |c| c.potential_value.to_f })
  json.cards column_cards do |card|
    json.partial! 'api/v1/accounts/kanban/cards/card', locals: { card: card, unread_counts: unread_counts }
  end
end
