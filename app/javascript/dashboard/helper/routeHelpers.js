import {
  hasPermissions,
  getUserPermissions,
  getCurrentAccount,
} from './permissionsHelper';

import {
  ROLES,
  CONVERSATION_PERMISSIONS,
  CONTACT_PERMISSIONS,
  REPORTS_PERMISSIONS,
  PORTAL_PERMISSIONS,
} from 'dashboard/constants/permissions.js';

export const routeIsAccessibleFor = (route, userPermissions = []) => {
  const { meta: { permissions: routePermissions = [] } = {} } = route;
  return hasPermissions(routePermissions, userPermissions);
};

// Custom (PR9): retorna 'kanban' como landing padrão se kanban_enabled !== false.
// Usando !== false em vez de === true para não quebrar se o atributo chegar undefined/null.
export const getDefaultLandingPath = user =>
  user?.kanban_enabled !== false ? 'kanban' : 'dashboard';

export const defaultRedirectPage = (to, permissions, user) => {
  const { accountId } = to.params;
  const defaultPath = getDefaultLandingPath(user);

  const permissionRoutes = [
    {
      permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
      path: defaultPath,
    },
    { permissions: [CONTACT_PERMISSIONS], path: 'contacts' },
    { permissions: [REPORTS_PERMISSIONS], path: 'reports/overview' },
    { permissions: [PORTAL_PERMISSIONS], path: 'portals' },
  ];

  const route = permissionRoutes.find(({ permissions: routePermissions }) =>
    hasPermissions(routePermissions, permissions)
  );

  return `accounts/${accountId}/${route ? route.path : defaultPath}`;
};

const validateActiveAccountRoutes = (to, user) => {
  // If the current account is active, then check for the route permissions
  // Custom (PR9): usa kanban como landing padrão quando kanban_enabled !== false
  const accountDashboardURL = `accounts/${to.params.accountId}/${getDefaultLandingPath(user)}`;

  // If the user is trying to access suspended route, redirect them to dashboard
  if (to.name === 'account_suspended') {
    return accountDashboardURL;
  }

  const userPermissions = getUserPermissions(user, to.params.accountId);

  const isAccessible = routeIsAccessibleFor(to, userPermissions);
  // If the route is not accessible for the user, return to dashboard screen
  return isAccessible ? null : defaultRedirectPage(to, userPermissions, user);
};

export const validateLoggedInRoutes = (to, user) => {
  const currentAccount = getCurrentAccount(user, Number(to.params.accountId));
  // If current account is missing, either user does not have
  // access to the account or the account is deleted, return to login screen
  if (!currentAccount) {
    return `app/login`;
  }

  const isCurrentAccountActive = currentAccount.status === 'active';

  if (isCurrentAccountActive) {
    return validateActiveAccountRoutes(to, user);
  }

  // If the current account is not active, only the suspended screen is
  // reachable; administrators can also access billing to restore the account
  const userPermissions = getUserPermissions(user, to.params.accountId);
  const accessibleRoutes = userPermissions.includes('administrator')
    ? ['account_suspended', 'billing_settings_index']
    : ['account_suspended'];

  if (!accessibleRoutes.includes(to.name)) {
    return `accounts/${to.params.accountId}/suspended`;
  }

  // Proceed to the route if none of the above conditions are met
  return null;
};

export const isAConversationRoute = (
  routeName,
  includeBase = false,
  includeExtended = true
) => {
  const baseRoutes = [
    'home',
    'conversation_mentions',
    'conversation_unattended',
    'inbox_dashboard',
    'label_conversations',
    'team_conversations',
    'folder_conversations',
    'conversation_participating',
  ];
  const extendedRoutes = [
    'inbox_conversation',
    'conversation_through_mentions',
    'conversation_through_unattended',
    'conversation_through_inbox',
    'conversations_through_label',
    'conversations_through_team',
    'conversations_through_folders',
    'conversation_through_participating',
  ];

  const routes = [
    ...(includeBase ? baseRoutes : []),
    ...(includeExtended ? extendedRoutes : []),
  ];

  return routes.includes(routeName);
};

export const getConversationDashboardRoute = routeName => {
  switch (routeName) {
    case 'inbox_conversation':
      return 'home';
    case 'conversation_through_mentions':
      return 'conversation_mentions';
    case 'conversation_through_unattended':
      return 'conversation_unattended';
    case 'conversations_through_label':
      return 'label_conversations';
    case 'conversations_through_team':
      return 'team_conversations';
    case 'conversations_through_folders':
      return 'folder_conversations';
    case 'conversation_through_participating':
      return 'conversation_participating';
    case 'conversation_through_inbox':
      return 'inbox_dashboard';
    default:
      return null;
  }
};

export const isAInboxViewRoute = (routeName, includeBase = false) => {
  const baseRoutes = ['inbox_view'];
  const extendedRoutes = ['inbox_view_conversation'];
  const routeNames = includeBase
    ? [...baseRoutes, ...extendedRoutes]
    : extendedRoutes;
  return routeNames.includes(routeName);
};

export const isUpgradePageBypassRoute = routeName =>
  [
    'billing_settings_index',
    'settings_inbox_list',
    'general_settings_index',
    'agent_list',
  ].includes(routeName);
