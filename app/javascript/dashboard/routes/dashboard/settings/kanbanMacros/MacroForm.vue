<script setup>
import { computed, onActivated, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import KanbanAPI from 'dashboard/api/kanban';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ConfirmButton from 'dashboard/components-next/button/ConfirmButton.vue';
import MacroBuilder from './MacroBuilder.vue';

const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const macroId = computed(() => route.params.macroId || null);
const isEdit = computed(() => !!macroId.value);

const isLoading = ref(false);
const isSaving = ref(false);
const isRestoring = ref(false);
const validationError = ref('');

const form = ref({
  name: '',
  description: '',
  enabled: true,
  triggers: [],
  conditions: [],
  actions: [],
  system: false,
});

const schema = computed(
  () =>
    getters['kanbanMacros/getSchema'].value || {
      triggers: [],
      conditions: [],
      actions: [],
    }
);

const pageTitle = computed(() =>
  isEdit.value
    ? t('KANBAN_MACROS.FORM.EDIT_TITLE')
    : t('KANBAN_MACROS.FORM.NEW_TITLE')
);

const validate = () => {
  if (!form.value.name.trim()) {
    validationError.value = t('KANBAN_MACROS.FORM.VALIDATION.NAME_REQUIRED');
    return false;
  }
  if (form.value.triggers.length === 0) {
    validationError.value = t(
      'KANBAN_MACROS.FORM.VALIDATION.AT_LEAST_ONE_TRIGGER'
    );
    return false;
  }
  if (form.value.actions.length === 0) {
    validationError.value = t(
      'KANBAN_MACROS.FORM.VALIDATION.AT_LEAST_ONE_ACTION'
    );
    return false;
  }
  validationError.value = '';
  return true;
};

const handleSave = async () => {
  if (!validate()) return;
  isSaving.value = true;
  try {
    const payload = {
      name: form.value.name.trim(),
      description: form.value.description.trim(),
      enabled: form.value.enabled,
      triggers: form.value.triggers,
      conditions: form.value.conditions,
      actions: form.value.actions,
    };
    if (isEdit.value) {
      await store.dispatch('kanbanMacros/updateMacro', {
        id: macroId.value,
        ...payload,
      });
    } else {
      await store.dispatch('kanbanMacros/createMacro', payload);
    }
    router.push({ name: 'kanban_macros_list' });
  } catch {
    useAlert(t('KANBAN_MACROS.ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const handleRestore = async () => {
  isRestoring.value = true;
  try {
    const macro = await store.dispatch(
      'kanbanMacros/restoreMacro',
      macroId.value
    );
    form.value.triggers = macro?.triggers || form.value.triggers;
    form.value.conditions = macro?.conditions || form.value.conditions;
    form.value.actions = macro?.actions || form.value.actions;
  } catch {
    useAlert(t('KANBAN_MACROS.ERROR'));
  } finally {
    isRestoring.value = false;
  }
};

const handleCancel = () => {
  router.push({ name: 'kanban_macros_list' });
};

const resetForm = () => {
  form.value = {
    name: '',
    description: '',
    enabled: true,
    triggers: [],
    conditions: [],
    actions: [],
    system: false,
  };
  validationError.value = '';
};

const populateForm = macro => {
  form.value = {
    name: macro.name || '',
    description: macro.description || '',
    enabled: macro.enabled ?? true,
    triggers: macro.triggers ? JSON.parse(JSON.stringify(macro.triggers)) : [],
    conditions: macro.conditions
      ? JSON.parse(JSON.stringify(macro.conditions))
      : [],
    actions: macro.actions ? JSON.parse(JSON.stringify(macro.actions)) : [],
    system: macro.system || false,
  };
  validationError.value = '';
};

const initForm = async () => {
  isLoading.value = true;
  resetForm();
  try {
    await store.dispatch('kanbanMacros/fetchSchema');
    if (isEdit.value) {
      const { data } = await KanbanAPI.showMacro(macroId.value);
      populateForm(data);
    }
  } catch {
    useAlert(t('KANBAN_MACROS.ERROR'));
  } finally {
    isLoading.value = false;
  }
};

onMounted(initForm);
onActivated(initForm);
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="$t('KANBAN_MACROS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="pageTitle"
        :back-button-label="$t('KANBAN_MACROS.TITLE')"
      />
    </template>

    <template #body>
      <div class="flex flex-col gap-6 max-w-2xl">
        <!-- Basic fields -->
        <div class="flex flex-col gap-4">
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium text-n-slate-12">
              {{ $t('KANBAN_MACROS.FORM.NAME_LABEL') }}
              <span class="text-n-ruby-9 ml-0.5">*</span>
            </label>
            <input
              v-model="form.name"
              type="text"
              :placeholder="$t('KANBAN_MACROS.FORM.NAME_PLACEHOLDER')"
              class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-brand"
            />
          </div>

          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium text-n-slate-12">
              {{ $t('KANBAN_MACROS.FORM.DESCRIPTION_LABEL') }}
            </label>
            <textarea
              v-model="form.description"
              rows="2"
              class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-brand resize-none"
            />
          </div>

          <div class="flex items-center gap-3">
            <input
              id="macro-enabled"
              v-model="form.enabled"
              type="checkbox"
              class="cursor-pointer"
            />
            <label
              for="macro-enabled"
              class="text-sm font-medium text-n-slate-12 cursor-pointer"
            >
              {{ $t('KANBAN_MACROS.ENABLED') }}
            </label>
          </div>
        </div>

        <!-- Divider -->
        <div class="border-t border-n-weak" />

        <!-- Builders -->
        <MacroBuilder
          v-model="form.triggers"
          kind="trigger"
          :available-types="schema.triggers || []"
        />

        <MacroBuilder
          v-model="form.conditions"
          kind="condition"
          :available-types="schema.conditions || []"
        />

        <MacroBuilder
          v-model="form.actions"
          kind="action"
          :available-types="schema.actions || []"
        />

        <!-- Validation error -->
        <p v-if="validationError" class="text-sm text-n-ruby-11">
          {{ validationError }}
        </p>

        <!-- Actions -->
        <div class="flex items-center gap-3 pt-2">
          <Button
            :label="$t('KANBAN_MACROS.FORM.SAVE')"
            size="sm"
            :is-loading="isSaving"
            @click="handleSave"
          />
          <Button
            :label="$t('KANBAN_MACROS.FORM.CANCEL')"
            slate
            sm
            @click="handleCancel"
          />
          <ConfirmButton
            v-if="isEdit && form.system"
            :label="$t('KANBAN_MACROS.FORM.RESTORE_DEFAULT')"
            :confirm-label="$t('KANBAN_MACROS.FORM.RESTORE_CONFIRM')"
            color="slate"
            size="sm"
            :is-loading="isRestoring"
            @click="handleRestore"
          />
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
