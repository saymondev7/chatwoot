<script setup>
import { computed, onBeforeMount, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useStoreGetters } from 'dashboard/composables/store';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();
const route = useRoute();

const newName = ref('');
const newType = ref('standard');
const editingId = ref(null);
const editingName = ref('');
const editingType = ref('standard');
const loading = ref({});

const classifications = computed(
  () => getters['conversationClassifications/getAll'].value
);
const uiFlags = computed(
  () => getters['conversationClassifications/getUIFlags'].value
);

const currentAccount = computed(
  () =>
    getters['accounts/getAccount'].value(Number(route.params.accountId)) || {}
);

const requireClassification = computed(
  () =>
    currentAccount.value?.settings?.require_classification_on_resolve !== false
);

const requireClosingNote = computed(
  () => currentAccount.value?.settings?.require_closing_note_on_resolve === true
);

const tableHeaders = computed(() => [
  t('CLASSIFICATION_SETTINGS.TABLE.NAME'),
  t('CLASSIFICATION_SETTINGS.TABLE.RESULT'),
  t('CLASSIFICATION_SETTINGS.TABLE.ACTIONS'),
]);

const typeOptions = computed(() => [
  {
    value: 'standard',
    label: t('CLASSIFICATION_SETTINGS.FORM.RESULT_OPTIONS.STANDARD'),
  },
  { value: 'won', label: t('CLASSIFICATION_SETTINGS.FORM.RESULT_OPTIONS.WON') },
  {
    value: 'lost',
    label: t('CLASSIFICATION_SETTINGS.FORM.RESULT_OPTIONS.LOST'),
  },
]);

const typeBadgeClass = type => {
  if (type === 'won') return 'bg-n-teal-2 text-n-teal-11';
  if (type === 'lost') return 'bg-n-ruby-2 text-n-ruby-11';
  return 'bg-n-slate-2 text-n-slate-10';
};

const typeLabel = type => {
  if (type === 'won')
    return t('CLASSIFICATION_SETTINGS.FORM.RESULT_OPTIONS.WON');
  if (type === 'lost')
    return t('CLASSIFICATION_SETTINGS.FORM.RESULT_OPTIONS.LOST');
  return t('CLASSIFICATION_SETTINGS.FORM.RESULT_OPTIONS.STANDARD');
};

const addClassification = async () => {
  if (!newName.value.trim()) return;
  try {
    await store.dispatch('conversationClassifications/create', {
      name: newName.value.trim(),
      classification_type: newType.value,
    });
    useAlert(t('CLASSIFICATION_SETTINGS.CREATE.SUCCESS'));
    newName.value = '';
    newType.value = 'standard';
  } catch {
    useAlert(t('CLASSIFICATION_SETTINGS.CREATE.ERROR'));
  }
};

const startEdit = item => {
  editingId.value = item.id;
  editingName.value = item.name;
  editingType.value = item.classification_type || 'standard';
};

const cancelEdit = () => {
  editingId.value = null;
  editingName.value = '';
  editingType.value = 'standard';
};

const saveEdit = async id => {
  if (!editingName.value.trim()) return;
  try {
    await store.dispatch('conversationClassifications/update', {
      id,
      name: editingName.value.trim(),
      classification_type: editingType.value,
    });
    useAlert(t('CLASSIFICATION_SETTINGS.UPDATE.SUCCESS'));
    cancelEdit();
  } catch {
    useAlert(t('CLASSIFICATION_SETTINGS.UPDATE.ERROR'));
  }
};

const deleteClassification = async id => {
  loading.value[id] = true;
  try {
    await store.dispatch('conversationClassifications/delete', id);
    useAlert(t('CLASSIFICATION_SETTINGS.DELETE.SUCCESS'));
  } catch {
    useAlert(t('CLASSIFICATION_SETTINGS.DELETE.ERROR'));
  } finally {
    loading.value[id] = false;
  }
};

const updateSetting = async (key, value) => {
  try {
    await store.dispatch('accounts/update', { [key]: value });
  } catch {
    useAlert(t('GENERAL_SETTINGS.UPDATE.ERROR'));
  }
};

onBeforeMount(() => {
  store.dispatch('conversationClassifications/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('CLASSIFICATION_SETTINGS.LOADING')"
    :no-records-found="false"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('CLASSIFICATION_SETTINGS.TITLE')"
        :description="$t('CLASSIFICATION_SETTINGS.DESCRIPTION')"
        feature-name="conversation_classifications"
      />
    </template>
    <template #body>
      <!-- Required fields toggles -->
      <div
        class="flex flex-col gap-4 mb-6 p-4 border border-n-weak rounded-lg bg-n-alpha-1"
      >
        <h3 class="text-sm font-semibold text-n-slate-12">
          {{ $t('CLASSIFICATION_SETTINGS.SETTINGS.TITLE') }}
        </h3>
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-n-slate-12">
              {{
                $t('CLASSIFICATION_SETTINGS.SETTINGS.REQUIRE_CLASSIFICATION')
              }}
            </p>
            <p class="text-xs text-n-slate-10">
              {{
                $t(
                  'CLASSIFICATION_SETTINGS.SETTINGS.REQUIRE_CLASSIFICATION_DESC'
                )
              }}
            </p>
          </div>
          <input
            type="checkbox"
            :checked="requireClassification"
            class="cursor-pointer"
            @change="
              updateSetting(
                'require_classification_on_resolve',
                $event.target.checked
              )
            "
          />
        </div>
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-n-slate-12">
              {{ $t('CLASSIFICATION_SETTINGS.SETTINGS.REQUIRE_CLOSING_NOTE') }}
            </p>
            <p class="text-xs text-n-slate-10">
              {{
                $t('CLASSIFICATION_SETTINGS.SETTINGS.REQUIRE_CLOSING_NOTE_DESC')
              }}
            </p>
          </div>
          <input
            type="checkbox"
            :checked="requireClosingNote"
            class="cursor-pointer"
            @change="
              updateSetting(
                'require_closing_note_on_resolve',
                $event.target.checked
              )
            "
          />
        </div>
      </div>

      <!-- Add new classification -->
      <div class="flex flex-col gap-2 mb-4">
        <div class="flex gap-2 items-center">
          <input
            v-model="newName"
            type="text"
            :placeholder="$t('CLASSIFICATION_SETTINGS.FORM.PLACEHOLDER')"
            class="flex-1 min-w-0 px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-brand"
            @keydown.enter="addClassification"
          />
          <select
            v-model="newType"
            v-tooltip.top="$t('CLASSIFICATION_SETTINGS.FORM.RESULT_HINT')"
            class="shrink-0 w-36 pl-3 pr-8 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          >
            <option
              v-for="opt in typeOptions"
              :key="opt.value"
              :value="opt.value"
            >
              {{ opt.label }}
            </option>
          </select>
          <Button
            :label="$t('CLASSIFICATION_SETTINGS.FORM.ADD')"
            size="sm"
            class="shrink-0"
            :is-loading="uiFlags.isCreating"
            :disabled="!newName.trim() || uiFlags.isCreating"
            @click="addClassification"
          />
        </div>
      </div>

      <!-- Classifications table -->
      <BaseTable
        :headers="tableHeaders"
        :items="classifications"
        :no-data-message="$t('CLASSIFICATION_SETTINGS.LIST.EMPTY')"
      >
        <template #row="{ items }">
          <BaseTableRow v-for="item in items" :key="item.id" :item="item">
            <template #default>
              <BaseTableCell>
                <div
                  v-if="editingId === item.id"
                  class="flex gap-2 items-center"
                >
                  <input
                    v-model="editingName"
                    type="text"
                    class="flex-1 px-2 py-1 text-sm border rounded border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
                    @keydown.enter="saveEdit(item.id)"
                    @keydown.esc="cancelEdit"
                  />
                  <Button
                    icon="i-lucide-check"
                    slate
                    sm
                    @click="saveEdit(item.id)"
                  />
                  <Button icon="i-lucide-x" slate sm @click="cancelEdit" />
                </div>
                <span v-else class="text-body-main text-n-slate-12">
                  {{ item.name }}
                </span>
              </BaseTableCell>

              <BaseTableCell>
                <select
                  v-if="editingId === item.id"
                  v-model="editingType"
                  class="px-2 py-1 text-sm border rounded border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
                >
                  <option
                    v-for="opt in typeOptions"
                    :key="opt.value"
                    :value="opt.value"
                  >
                    {{ opt.label }}
                  </option>
                </select>
                <span
                  v-else
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium"
                  :class="typeBadgeClass(item.classification_type)"
                >
                  {{ typeLabel(item.classification_type) }}
                </span>
              </BaseTableCell>

              <BaseTableCell align="end">
                <div class="flex gap-3 justify-end flex-shrink-0">
                  <Button
                    v-if="editingId !== item.id"
                    v-tooltip.top="$t('CLASSIFICATION_SETTINGS.TABLE.EDIT')"
                    icon="i-woot-edit-pen"
                    slate
                    sm
                    @click="startEdit(item)"
                  />
                  <Button
                    v-if="editingId !== item.id"
                    v-tooltip.top="$t('CLASSIFICATION_SETTINGS.TABLE.DELETE')"
                    icon="i-woot-bin"
                    slate
                    sm
                    class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                    :is-loading="loading[item.id]"
                    @click="deleteClassification(item.id)"
                  />
                </div>
              </BaseTableCell>
            </template>
          </BaseTableRow>
        </template>
      </BaseTable>
    </template>
  </SettingsLayout>
</template>
