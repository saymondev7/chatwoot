<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const props = defineProps({
  schedule: { type: Object, default: null },
  isSaving: { type: Boolean, default: false },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();

const dialogRef = ref(null);

const EMPTY_FORM = {
  name: '',
  startsOn: '',
  endsOn: '',
  scheduleType: 'closed',
  opensAt: '09:00',
  closesAt: '18:00',
  message: '',
};

const form = ref({ ...EMPTY_FORM });

const typeOptions = computed(() => [
  { value: 'closed', label: t('SPECIAL_SCHEDULES.TYPES.CLOSED') },
  { value: 'custom_hours', label: t('SPECIAL_SCHEDULES.TYPES.CUSTOM_HOURS') },
  { value: 'promotion', label: t('SPECIAL_SCHEDULES.TYPES.PROMOTION') },
  { value: 'notice', label: t('SPECIAL_SCHEDULES.TYPES.NOTICE') },
]);

const isCustomHours = computed(
  () => form.value.scheduleType === 'custom_hours'
);

const isValid = computed(
  () =>
    form.value.name.trim() &&
    form.value.startsOn &&
    form.value.endsOn &&
    form.value.endsOn >= form.value.startsOn &&
    form.value.message.trim() &&
    (!isCustomHours.value ||
      (form.value.opensAt &&
        form.value.closesAt &&
        form.value.closesAt > form.value.opensAt))
);

const padTime = (hour, minutes) =>
  `${String(hour ?? 0).padStart(2, '0')}:${String(minutes ?? 0).padStart(2, '0')}`;

watch(
  () => props.schedule,
  schedule => {
    form.value = schedule
      ? {
          name: schedule.name,
          startsOn: schedule.starts_on,
          endsOn: schedule.ends_on,
          scheduleType: schedule.schedule_type,
          opensAt:
            schedule.schedule_type === 'custom_hours'
              ? padTime(schedule.open_hour, schedule.open_minutes)
              : EMPTY_FORM.opensAt,
          closesAt:
            schedule.schedule_type === 'custom_hours'
              ? padTime(schedule.close_hour, schedule.close_minutes)
              : EMPTY_FORM.closesAt,
          message: schedule.message,
        }
      : { ...EMPTY_FORM };
  },
  { immediate: true }
);

const buildPayload = () => {
  const [openHour, openMinutes] = form.value.opensAt.split(':');
  const [closeHour, closeMinutes] = form.value.closesAt.split(':');

  return {
    name: form.value.name.trim(),
    starts_on: form.value.startsOn,
    ends_on: form.value.endsOn,
    schedule_type: form.value.scheduleType,
    message: form.value.message.trim(),
    open_hour: isCustomHours.value ? Number(openHour) : null,
    open_minutes: isCustomHours.value ? Number(openMinutes) : null,
    close_hour: isCustomHours.value ? Number(closeHour) : null,
    close_minutes: isCustomHours.value ? Number(closeMinutes) : null,
  };
};

const handleSubmit = () => emit('submit', buildPayload());

defineExpose({
  open: () => dialogRef.value?.open(),
  close: () => dialogRef.value?.close(),
});
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="xl"
    overflow-y-auto
    :title="
      schedule
        ? $t('SPECIAL_SCHEDULES.FORM.EDIT_TITLE')
        : $t('SPECIAL_SCHEDULES.FORM.CREATE_TITLE')
    "
    :confirm-button-label="$t('SPECIAL_SCHEDULES.FORM.SAVE')"
    :cancel-button-label="$t('SPECIAL_SCHEDULES.FORM.CANCEL')"
    :disable-confirm-button="!isValid"
    :is-loading="isSaving"
    @confirm="handleSubmit"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="form.name"
        :label="$t('SPECIAL_SCHEDULES.FORM.NAME_LABEL')"
        :placeholder="$t('SPECIAL_SCHEDULES.FORM.NAME_PLACEHOLDER')"
      />

      <div class="grid grid-cols-2 gap-4">
        <Input
          v-model="form.startsOn"
          type="date"
          :label="$t('SPECIAL_SCHEDULES.FORM.STARTS_ON_LABEL')"
        />
        <Input
          v-model="form.endsOn"
          type="date"
          :label="$t('SPECIAL_SCHEDULES.FORM.ENDS_ON_LABEL')"
        />
      </div>

      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('SPECIAL_SCHEDULES.FORM.TYPE_LABEL') }}
        </label>
        <Select v-model="form.scheduleType" :options="typeOptions" />
      </div>

      <div v-if="isCustomHours" class="grid grid-cols-2 gap-4">
        <Input
          v-model="form.opensAt"
          type="time"
          :label="$t('SPECIAL_SCHEDULES.FORM.OPENS_AT_LABEL')"
        />
        <Input
          v-model="form.closesAt"
          type="time"
          :label="$t('SPECIAL_SCHEDULES.FORM.CLOSES_AT_LABEL')"
        />
      </div>

      <TextArea
        v-model="form.message"
        :label="$t('SPECIAL_SCHEDULES.FORM.MESSAGE_LABEL')"
        :placeholder="$t('SPECIAL_SCHEDULES.FORM.MESSAGE_PLACEHOLDER')"
        :message="$t('SPECIAL_SCHEDULES.FORM.MESSAGE_HINT')"
        :max-length="500"
        show-character-count
        auto-height
      />
    </div>
  </Dialog>
</template>
