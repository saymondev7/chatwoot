import { insertSortedByRule } from './sort';

export default {
  SET_BOARD(state, board) {
    state.board = board;
    state.columns = board.columns || [];
    const cards = {};
    (board.columns || []).forEach(col => {
      cards[col.id] = col.cards || [];
    });
    state.cards = cards;
  },

  SET_COLUMNS(state, columns) {
    state.columns = columns;
  },

  ADD_COLUMN(state, column) {
    state.columns.push(column);
    state.cards[column.id] = [];
  },

  UPDATE_COLUMN(state, column) {
    const idx = state.columns.findIndex(c => c.id === column.id);
    if (idx !== -1) state.columns.splice(idx, 1, column);
  },

  REMOVE_COLUMN(state, columnId) {
    state.columns = state.columns.filter(c => c.id !== columnId);
    delete state.cards[columnId];
  },

  SET_CARDS(state, { columnId, cards }) {
    state.cards = { ...state.cards, [columnId]: cards };
  },

  ADD_CARD(state, card) {
    const columnCards = state.cards[card.kanban_column_id] || [];
    state.cards = {
      ...state.cards,
      [card.kanban_column_id]: [...columnCards, card],
    };
  },

  UPDATE_CARD(state, card) {
    const columnCards = state.cards[card.kanban_column_id] || [];
    const idx = columnCards.findIndex(c => c.id === card.id);
    if (idx !== -1) {
      const updated = [...columnCards];
      updated.splice(idx, 1, card);
      state.cards = { ...state.cards, [card.kanban_column_id]: updated };
    }
  },

  REMOVE_CARD(state, { cardId, columnId }) {
    state.cards = {
      ...state.cards,
      [columnId]: (state.cards[columnId] || []).filter(c => c.id !== cardId),
    };
  },

  MOVE_CARD_OPTIMISTIC(state, { card, targetColumnId }) {
    const sourceColumnId = card.kanban_column_id;
    if (String(sourceColumnId) === String(targetColumnId)) return;

    const targetColumn = state.columns.find(
      c => String(c.id) === String(targetColumnId)
    );
    const updatedCard = {
      ...card,
      kanban_column_id: targetColumnId,
      entered_stage_at: new Date().toISOString(),
    };

    const sourceCards = (state.cards[sourceColumnId] || []).filter(
      c => c.id !== card.id
    );
    const targetCards = insertSortedByRule(
      (state.cards[targetColumnId] || []).filter(c => c.id !== card.id),
      updatedCard,
      targetColumn
    );

    state.cards = {
      ...state.cards,
      [sourceColumnId]: sourceCards,
      [targetColumnId]: targetCards,
    };
  },

  REVERT_CARD_MOVE(state, { card, originalColumnId }) {
    const originalColumn = state.columns.find(
      c => String(c.id) === String(originalColumnId)
    );
    const newCards = { ...state.cards };

    Object.keys(newCards).forEach(colId => {
      newCards[colId] = newCards[colId].filter(c => c.id !== card.id);
    });

    newCards[originalColumnId] = insertSortedByRule(
      newCards[originalColumnId] || [],
      { ...card, kanban_column_id: originalColumnId },
      originalColumn
    );

    state.cards = newCards;
  },

  SET_SELECTED_CARD(state, card) {
    state.selectedCard = card;
  },

  SET_UI_FLAG(state, flags) {
    state.uiFlags = { ...state.uiFlags, ...flags };
  },

  // Custom (PR8): badge de mensagens não lidas
  INCREMENT_CARD_UNREAD(state, conversationId) {
    const allCards = Object.values(state.cards).flat();
    const card = allCards.find(c => c.conversation_id === conversationId);
    if (!card) return;
    const columnCards = state.cards[card.kanban_column_id] || [];
    const idx = columnCards.findIndex(c => c.id === card.id);
    if (idx === -1) return;
    const updated = [...columnCards];
    updated[idx] = {
      ...updated[idx],
      unread_count: (updated[idx].unread_count || 0) + 1,
    };
    state.cards = { ...state.cards, [card.kanban_column_id]: updated };
  },

  CLEAR_CARD_UNREAD(state, cardId) {
    const colId = Object.keys(state.cards).find(id =>
      state.cards[id].some(c => c.id === cardId)
    );
    if (!colId) return;
    const idx = state.cards[colId].findIndex(c => c.id === cardId);
    const updated = [...state.cards[colId]];
    updated[idx] = { ...updated[idx], unread_count: 0 };
    state.cards = { ...state.cards, [colId]: updated };
  },
};
