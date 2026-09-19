// Itens de topo do menu lateral (Sidebar.vue) que podem ser ocultados por
// Função Personalizada — ver CustomRoleModal.vue (checkboxes) e
// CustomRole#hidden_sidebar_items (backend). Cada item novo adicionado à
// sidebar no futuro só passa a ser configurável aqui depois de ganhar uma
// entrada nesta lista; até lá, fica sempre visível (comportamento padrão
// de "nada oculto" quando a chave não está em hidden_sidebar_items).
export const SIDEBAR_VISIBILITY_ITEMS = [
  { key: 'inbox', labelKey: 'SIDEBAR.INBOX' },
  { key: 'conversations', labelKey: 'SIDEBAR.CONVERSATIONS' },
  { key: 'captain', labelKey: 'SIDEBAR.CAPTAIN' },
  { key: 'calls', labelKey: 'SIDEBAR.CALLS' },
  { key: 'contacts', labelKey: 'SIDEBAR.CONTACTS' },
  { key: 'companies', labelKey: 'SIDEBAR.COMPANIES' },
  { key: 'reports', labelKey: 'SIDEBAR.REPORTS' },
  { key: 'kanban', labelKey: 'KANBAN.TITLE' },
  { key: 'campaigns', labelKey: 'SIDEBAR.CAMPAIGNS' },
  { key: 'help_center', labelKey: 'SIDEBAR.HELP_CENTER.TITLE' },
  { key: 'settings', labelKey: 'SIDEBAR.SETTINGS' },
];
