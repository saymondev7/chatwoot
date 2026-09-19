<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SpecialSchedulesAPI from 'dashboard/api/specialSchedules';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ConfirmButton from 'dashboard/components-next/button/ConfirmButton.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';
import SpecialScheduleDialog from './SpecialScheduleDialog.vue';

const { t } = useI18n();

const schedules = ref([]);
const isLoading = ref(false);
const hasError = ref(false);
const isSaving = ref(false);
const togglingId = ref(null);
const deletingId = ref(null);
const selectedSchedule = ref(null);
const dialogRef = ref(null);

const tableHeaders = computed(() => [
  t('SPECIAL_SCHEDULES.TABLE.NAME'),
  t('SPECIAL_SCHEDULES.TABLE.PERIOD'),
  t('SPECIAL_SCHEDULES.TABLE.TYPE'),
  t('SPECIAL_SCHEDULES.TABLE.MESSAGE'),
  t('SPECIAL_SCHEDULES.TABLE.ENABLED'),
  '',
]);

const typeLabels = computed(() => ({
  closed: t('SPECIAL_SCHEDULES.TYPES.CLOSED'),
  custom_hours: t('SPECIAL_SCHEDULES.TYPES.CUSTOM_HOURS'),
  promotion: t('SPECIAL_SCHEDULES.TYPES.PROMOTION'),
  notice: t('SPECIAL_SCHEDULES.TYPES.NOTICE'),
}));

const typeLabel = schedule => typeLabels.value[schedule.schedule_type];

const formatDate = date => new Date(`${date}T00:00:00`).toLocaleDateString();

const periodLabel = schedule =>
  schedule.starts_on === schedule.ends_on
    ? formatDate(schedule.starts_on)
    : `${formatDate(schedule.starts_on)} – ${formatDate(schedule.ends_on)}`;

const fetchSchedules = async () => {
  isLoading.value = true;
  hasError.value = false;
  try {
    const { data } = await SpecialSchedulesAPI.get();
    schedules.value = data;
  } catch {
    hasError.value = true;
  } finally {
    isLoading.value = false;
  }
};

const openDialog = (schedule = null) => {
  selectedSchedule.value = schedule;
  dialogRef.value.open();
};

const handleSubmit = async payload => {
  isSaving.value = true;
  try {
    if (selectedSchedule.value) {
      await SpecialSchedulesAPI.update(selectedSchedule.value.id, payload);
    } else {
      await SpecialSchedulesAPI.create(payload);
    }
    dialogRef.value.close();
    await fetchSchedules();
  } catch {
    useAlert(t('SPECIAL_SCHEDULES.ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const handleToggle = async (schedule, enabled) => {
  togglingId.value = schedule.id;
  try {
    await SpecialSchedulesAPI.update(schedule.id, { enabled });
    await fetchSchedules();
  } catch {
    useAlert(t('SPECIAL_SCHEDULES.ERROR'));
  } finally {
    togglingId.value = null;
  }
};

const handleDelete = async schedule => {
  deletingId.value = schedule.id;
  try {
    await SpecialSchedulesAPI.delete(schedule.id);
    await fetchSchedules();
  } catch {
    useAlert(t('SPECIAL_SCHEDULES.ERROR'));
  } finally {
    deletingId.value = null;
  }
};

onMounted(fetchSchedules);
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="$t('SPECIAL_SCHEDULES.LOADING')"
    :no-records-found="!isLoading && !hasError && schedules.length === 0"
    :no-records-message="$t('SPECIAL_SCHEDULES.EMPTY_STATE')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('SPECIAL_SCHEDULES.TITLE')"
        :description="$t('SPECIAL_SCHEDULES.SUBTITLE')"
      >
        <template #actions>
          <Button
            :label="$t('SPECIAL_SCHEDULES.NEW')"
            icon="i-lucide-plus"
            size="sm"
            @click="openDialog()"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <div v-if="hasError" class="py-8 text-center text-n-slate-11">
        {{ $t('SPECIAL_SCHEDULES.ERROR') }}
      </div>

      <BaseTable
        v-else
        :headers="tableHeaders"
        :items="schedules"
        :no-data-message="$t('SPECIAL_SCHEDULES.EMPTY_STATE')"
      >
        <template #row="{ items }">
          <BaseTableRow
            v-for="schedule in items"
            :key="schedule.id"
            :item="schedule"
          >
            <template #default>
              <BaseTableCell>
                <span class="font-medium text-body-main text-n-slate-12">
                  {{ schedule.name }}
                </span>
              </BaseTableCell>

              <BaseTableCell>
                <span class="text-sm text-n-slate-11">
                  {{ periodLabel(schedule) }}
                </span>
              </BaseTableCell>

              <BaseTableCell>
                <span class="text-sm text-n-slate-11">
                  {{ typeLabel(schedule) }}
                </span>
              </BaseTableCell>

              <BaseTableCell>
                <span class="text-sm truncate text-n-slate-10 max-w-80">
                  {{ schedule.message }}
                </span>
              </BaseTableCell>

              <BaseTableCell>
                <input
                  type="checkbox"
                  :checked="schedule.enabled"
                  :disabled="togglingId === schedule.id"
                  class="cursor-pointer"
                  @change="handleToggle(schedule, $event.target.checked)"
                />
              </BaseTableCell>

              <BaseTableCell align="end">
                <div class="flex justify-end gap-2">
                  <Button
                    v-tooltip.top="$t('SPECIAL_SCHEDULES.EDIT')"
                    icon="i-woot-edit-pen"
                    slate
                    sm
                    @click="openDialog(schedule)"
                  />
                  <ConfirmButton
                    v-tooltip.top="$t('SPECIAL_SCHEDULES.DELETE')"
                    icon="i-woot-bin"
                    color="slate"
                    size="sm"
                    :confirm-label="$t('SPECIAL_SCHEDULES.DELETE_CONFIRM')"
                    :is-loading="deletingId === schedule.id"
                    @click="handleDelete(schedule)"
                  />
                </div>
              </BaseTableCell>
            </template>
          </BaseTableRow>
        </template>
      </BaseTable>

      <SpecialScheduleDialog
        ref="dialogRef"
        :schedule="selectedSchedule"
        :is-saving="isSaving"
        @submit="handleSubmit"
      />
    </template>
  </SettingsLayout>
</template>
