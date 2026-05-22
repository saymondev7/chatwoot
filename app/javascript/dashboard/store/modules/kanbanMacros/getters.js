export default {
  getMacros: $state => $state.macros,
  getSchema: $state => $state.schema,
  getMacroById: $state => id => $state.macros.find(m => m.id === id),
};
