unread_counts = @card.conversation_id ? { @card.conversation_id => @card.conversation&.assignee_unread_incoming_messages&.count.to_i } : {}
json.partial! 'api/v1/accounts/kanban/cards/card', locals: { card: @card, unread_counts: unread_counts }
