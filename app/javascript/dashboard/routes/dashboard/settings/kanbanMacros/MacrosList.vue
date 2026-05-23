<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useStoreGetters } from 'dashboard/composables/store';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ConfirmButton from 'dashboard/components-next/button/ConfirmButton.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();
const router = useRouter();

const isLoading = ref(false);
const hasError = ref(false);
const togglingId = ref(null);
const deletingId = ref(null);

const macros = computed(() => getters['kanbanMacros/getMacros'].value);

const tableHeaders = computed(() => [
  t('KANBAN_MACROS.NAME'),
  t('KANBAN_MACROS.DESCRIPTION'),
  t('KANBAN_MACROS.ENABLED'),
  '',
]);

const goToNew = () => {
  router.push({ name: 'kanban_macros_new' });
};

const goToEdit = macroId => {
  router.push({ name: 'kanban_macros_edit', params: { macroId } });
};

const handleToggle = async (macro, enabled) => {
  togglingId.value = macro.id;
  try {
    await store.dispatch('kanbanMacros/toggleEnabled', {
      id: macro.id,
      enabled,
    });
  } catch {
    useAlert(t('KANBAN_MACROS.ERROR'));
  } finally {
    togglingId.value = null;
  }
};

const handleDelete = async macro => {
  deletingId.value = macro.id;
  try {
    await store.dispatch('kanbanMacros/deleteMacro', macro.id);
  } catch {
    useAlert(t('KANBAN_MACROS.ERROR'));
  } finally {
    deletingId.value = null;
  }
};

onMounted(async () => {
  isLoading.value = true;
  hasError.value = false;
  try {
    await store.dispatch('kanbanMacros/fetchMacros');
  } catch {
    hasError.value = true;
  } finally {
    isLoading.value = false;
  }
});
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="$t('KANBAN_MACROS.LOADING')"
    :no-records-found="!isLoading && !hasError && macros.length === 0"
    :no-records-message="$t('KANBAN_MACROS.EMPTY_STATE')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('KANBAN_MACROS.TITLE')"
        :description="$t('KANBAN_MACROS.SUBTITLE')"
      >
        <template #actions>
          <Button
            :label="$t('KANBAN_MACROS.NEW_MACRO')"
            icon="i-lucide-plus"
            size="sm"
            @click="goToNew"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <div v-if="hasError" class="py-8 text-center text-n-slate-11">
        {{ $t('KANBAN_MACROS.ERROR') }}
      </div>

      <div
        v-else-if="macros.length === 0"
        class="flex flex-col items-center justify-center py-20 gap-4"
      >
        <p class="text-n-slate-11 text-base">
          {{ $t('KANBAN_MACROS.EMPTY_STATE') }}
        </p>
        <Button
          :label="$t('KANBAN_MACROS.EMPTY_CTA')"
          icon="i-lucide-plus"
          size="sm"
          @click="goToNew"
        />
      </div>

      <BaseTable
        v-else
        :headers="tableHeaders"
        :items="macros"
        :no-data-message="$t('KANBAN_MACROS.EMPTY_STATE')"
      >
        <template #row="{ items }">
          <BaseTableRow v-for="macro in items" :key="macro.id" :item="macro">
            <template #default>
              <!-- Name + system badge -->
              <BaseTableCell>
                <div class="flex items-center gap-2">
                  <span class="text-body-main text-n-slate-12 font-medium">
                    {{ macro.name }}
                  </span>
                  <span
                    v-if="macro.system"
                    class="px-1.5 py-0.5 text-xs rounded bg-n-alpha-2 text-n-slate-10 border border-n-weak"
                  >
                    {{ $t('KANBAN_MACROS.SYSTEM_BADGE') }}
                  </span>
                </div>
              </BaseTableCell>

              <!-- Description -->
              <BaseTableCell>
                <span class="text-sm text-n-slate-10">
                  {{ macro.description || '—' }}
                </span>
              </BaseTableCell>

              <!-- Toggle enabled -->
              <BaseTableCell>
                <input
                  type="checkbox"
                  :checked="macro.enabled"
                  :disabled="togglingId === macro.id"
                  class="cursor-pointer"
                  @change="handleToggle(macro, $event.target.checked)"
                />
              </BaseTableCell>

              <!-- Actions -->
              <BaseTableCell align="end">
                <div class="flex gap-2 justify-end">
                  <Button
                    v-tooltip.top="$t('KANBAN_MACROS.EDIT')"
                    icon="i-woot-edit-pen"
                    slate
                    sm
                    @click="goToEdit(macro.id)"
                  />
                  <ConfirmButton
                    v-if="!macro.system"
                    v-tooltip.top="$t('KANBAN_MACROS.DELETE')"
                    icon="i-woot-bin"
                    color="slate"
                    size="sm"
                    :confirm-label="$t('KANBAN_MACROS.DELETE_CONFIRM')"
                    :is-loading="deletingId === macro.id"
                    @click="handleDelete(macro)"
                  />
                  <Button
                    v-else
                    v-tooltip.top="$t('KANBAN_MACROS.DELETE_SYSTEM_FORBIDDEN')"
                    icon="i-woot-bin"
                    slate
                    sm
                    disabled
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
