export default {
  SET_MACROS($state, macros) {
    $state.macros = macros;
  },

  SET_SCHEMA($state, schema) {
    $state.schema = schema;
  },

  ADD_MACRO($state, macro) {
    $state.macros = [...$state.macros, macro];
  },

  UPDATE_MACRO($state, updatedMacro) {
    $state.macros = $state.macros.map(m =>
      m.id === updatedMacro.id ? updatedMacro : m
    );
  },

  REMOVE_MACRO($state, id) {
    $state.macros = $state.macros.filter(m => m.id !== id);
  },

  RESET_MACROS($state) {
    $state.macros = [];
    $state.schema = null;
  },
};
