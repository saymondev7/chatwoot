import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/special-schedules'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'special_schedules_wrapper',
          meta: { permissions: ['administrator'] },
          redirect: to => ({
            name: 'special_schedules_list',
            params: to.params,
          }),
        },
        {
          path: 'list',
          name: 'special_schedules_list',
          meta: { permissions: ['administrator'] },
          component: Index,
        },
      ],
    },
  ],
};
