import KanbanAPI from '../../../api/kanban';

export default {
  async fetchMacros({ commit }) {
    commit('RESET_MACROS');
    const { data } = await KanbanAPI.fetchMacros();
    commit('SET_MACROS', data);
    return data;
  },

  async fetchSchema({ commit, state }) {
    if (state.schema) return state.schema;
    const { data } = await KanbanAPI.fetchSchema();
    commit('SET_SCHEMA', data);
    return data;
  },

  async createMacro({ commit }, params) {
    const { data } = await KanbanAPI.createMacro(params);
    commit('ADD_MACRO', data);
    return data;
  },

  async updateMacro({ commit }, { id, ...params }) {
    const { data } = await KanbanAPI.updateMacro(id, params);
    commit('UPDATE_MACRO', data);
    return data;
  },

  async deleteMacro({ commit }, id) {
    await KanbanAPI.deleteMacro(id);
    commit('REMOVE_MACRO', id);
  },

  async toggleEnabled({ commit }, { id, enabled }) {
    const { data } = await KanbanAPI.toggleMacroEnabled(id, enabled);
    commit('UPDATE_MACRO', data);
    return data;
  },

  async restoreMacro({ commit }, id) {
    const { data } = await KanbanAPI.restoreMacro(id);
    commit('UPDATE_MACRO', data);
    return data;
  },

  resetMacros({ commit }) {
    commit('RESET_MACROS');
  },
};
