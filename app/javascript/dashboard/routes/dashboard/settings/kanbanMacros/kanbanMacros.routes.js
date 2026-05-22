import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import MacrosList from './MacrosList.vue';
import MacroForm from './MacroForm.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/kanban/macros'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'kanban_macros_wrapper',
          meta: { permissions: ['administrator'] },
          redirect: to => ({
            name: 'kanban_macros_list',
            params: to.params,
          }),
        },
        {
          path: 'list',
          name: 'kanban_macros_list',
          meta: { permissions: ['administrator'] },
          component: MacrosList,
        },
        {
          path: 'new',
          name: 'kanban_macros_new',
          meta: { permissions: ['administrator'] },
          component: MacroForm,
        },
        {
          path: ':macroId/edit',
          name: 'kanban_macros_edit',
          meta: { permissions: ['administrator'] },
          component: MacroForm,
        },
      ],
    },
  ],
};
