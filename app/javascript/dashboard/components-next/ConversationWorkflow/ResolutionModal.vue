<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const emit = defineEmits(['submit', 'cancel']);

const store = useStore();
const getters = useStoreGetters();

const dialogRef = ref(null);
const conversationContext = ref(null);
const classificationId = ref(null);
const closingNote = ref('');
const storeBranch = ref(null);
const quotationNumber = ref('');
const excludeClassificationNames = ref([]);
const lockedClassificationId = ref(null);
const didConfirm = ref(false);

const STORE_OPTIONS = [
  { value: 'matriz', labelKey: 'RESOLUTION_MODAL.STORE_OPTIONS.MATRIZ' },
  { value: 'filial_cj', labelKey: 'RESOLUTION_MODAL.STORE_OPTIONS.FILIAL_CJ' },
];

const isQuotationInvalid = computed(
  () => quotationNumber.value !== '' && !/^\d{1,6}$/.test(quotationNumber.value)
);

const onQuotationInput = e => {
  const sanitized = e.target.value.replace(/\D/g, '').slice(0, 6);
  quotationNumber.value = sanitized;
};

const classifications = computed(
  () => getters['conversationClassifications/getAll'].value
);

const currentAccountId = computed(() => getters.getCurrentAccountId.value);
const currentAccount = computed(
  () => getters['accounts/getAccount'].value(currentAccountId.value) || {}
);

const requireClassification = computed(
  () =>
    currentAccount.value?.settings?.require_classification_on_resolve !== false
);

const requireClosingNote = computed(
  () => currentAccount.value?.settings?.require_closing_note_on_resolve === true
);

const classificationOptions = computed(() =>
  classifications.value
    .filter(c => !excludeClassificationNames.value.includes(c.name))
    .map(c => ({ value: c.id, label: c.name }))
);

const lockedClassificationLabel = computed(
  () =>
    classifications.value.find(c => c.id === lockedClassificationId.value)?.name
);

const isConfirmDisabled = computed(() => {
  if (requireClassification.value && !classificationId.value) return true;
  if (requireClosingNote.value && !closingNote.value.trim()) return true;
  if (isQuotationInvalid.value) return true;
  return false;
});

const open = context => {
  conversationContext.value = context;
  classificationId.value = context.classificationId || null;
  closingNote.value = context.closingNote || '';
  storeBranch.value = context.storeBranch || null;
  quotationNumber.value = context.quotationNumber || '';
  excludeClassificationNames.value = context.excludeClassificationNames || [];
  didConfirm.value = false;

  if (context.lockedClassificationName) {
    const found = classifications.value.find(
      c => c.name === context.lockedClassificationName
    );
    lockedClassificationId.value = found?.id || null;
    classificationId.value = found?.id || null;
  } else {
    lockedClassificationId.value = null;
  }

  dialogRef.value?.open();
};

const handleConfirm = () => {
  didConfirm.value = true;
  emit('submit', {
    context: conversationContext.value,
    classificationId: classificationId.value,
    closingNote: closingNote.value,
    storeBranch: storeBranch.value,
    quotationNumber: quotationNumber.value || null,
  });
  dialogRef.value?.close();
};

const handleClose = () => {
  if (!didConfirm.value) emit('cancel');
  didConfirm.value = false;
};

onMounted(() => {
  store.dispatch('conversationClassifications/get');
});

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="$t('RESOLUTION_MODAL.TITLE')"
    :description="$t('RESOLUTION_MODAL.DESCRIPTION')"
    :confirm-button-label="$t('RESOLUTION_MODAL.CONFIRM')"
    :cancel-button-label="$t('RESOLUTION_MODAL.CANCEL')"
    :disable-confirm-button="isConfirmDisabled"
    show-cancel-button
    @confirm="handleConfirm"
    @close="handleClose"
  >
    <div class="flex flex-col gap-4 pt-2">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('RESOLUTION_MODAL.CLASSIFICATION.LABEL') }}
          <span v-if="requireClassification" class="text-n-ruby-9">*</span>
        </label>

        <!-- Classificação travada (apenas leitura) -->
        <div
          v-if="lockedClassificationId"
          class="w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-2 text-n-slate-12"
        >
          {{ lockedClassificationLabel }}
        </div>

        <!-- Seletor normal -->
        <select
          v-else
          v-model="classificationId"
          class="w-full pl-3 pr-9 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
        >
          <option :value="null" disabled>
            {{ $t('RESOLUTION_MODAL.CLASSIFICATION.PLACEHOLDER') }}
          </option>
          <option
            v-for="option in classificationOptions"
            :key="option.value"
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </select>

        <p
          v-if="requireClassification && !classificationId"
          class="text-xs text-n-slate-10"
        >
          {{ $t('RESOLUTION_MODAL.CLASSIFICATION.REQUIRED_HINT') }}
        </p>
      </div>

      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('RESOLUTION_MODAL.CLOSING_NOTE.LABEL') }}
          <span v-if="requireClosingNote" class="text-n-ruby-9">*</span>
        </label>
        <textarea
          v-model="closingNote"
          :placeholder="$t('RESOLUTION_MODAL.CLOSING_NOTE.PLACEHOLDER')"
          rows="3"
          class="w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-brand resize-none"
        />
      </div>

      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('RESOLUTION_MODAL.STORE_LABEL') }}
        </label>
        <select
          v-model="storeBranch"
          class="w-full pl-3 pr-9 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
        >
          <option :value="null">
            {{ $t('RESOLUTION_MODAL.STORE_PLACEHOLDER') }}
          </option>
          <option
            v-for="option in STORE_OPTIONS"
            :key="option.value"
            :value="option.value"
          >
            {{ $t(option.labelKey) }}
          </option>
        </select>
      </div>

      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('RESOLUTION_MODAL.QUOTATION_NUMBER_LABEL') }}
        </label>
        <input
          :value="quotationNumber"
          type="text"
          inputmode="numeric"
          pattern="\d*"
          maxlength="6"
          :placeholder="$t('RESOLUTION_MODAL.QUOTATION_NUMBER_PLACEHOLDER')"
          class="w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-brand"
          @input="onQuotationInput"
        />
      </div>
    </div>
  </Dialog>
</template>
