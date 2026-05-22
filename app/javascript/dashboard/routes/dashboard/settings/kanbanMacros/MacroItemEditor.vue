<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DynamicConfigField from './DynamicConfigField.vue';

const props = defineProps({
  item: {
    type: Object,
    required: true,
  },
  typeSchema: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['update:item', 'remove']);

const { t } = useI18n();

const label = computed(() => props.typeSchema?.label || props.item.type);

const configFields = computed(() => {
  if (!props.typeSchema?.config_schema) return [];
  return Object.entries(props.typeSchema.config_schema).map(
    ([key, schema]) => ({
      key,
      schema,
    })
  );
});

const updateConfig = (key, value) => {
  emit('update:item', {
    ...props.item,
    config: { ...props.item.config, [key]: value },
  });
};
</script>

<template>
  <div
    class="flex items-start gap-2 p-3 rounded-lg border border-n-weak bg-n-alpha-1"
  >
    <Icon
      icon="i-woot-drag-indicator"
      class="flex-shrink-0 mt-0.5 text-n-slate-9 cursor-grab active:cursor-grabbing"
    />

    <div class="flex-1 min-w-0">
      <p class="text-sm font-medium text-n-slate-12 mb-2">{{ label }}</p>
      <div v-if="configFields.length > 0" class="flex flex-col gap-3">
        <DynamicConfigField
          v-for="field in configFields"
          :key="field.key"
          :field-key="field.key"
          :field-schema="field.schema"
          :model-value="item.config[field.key]"
          @update:model-value="updateConfig(field.key, $event)"
        />
      </div>
    </div>

    <Button
      v-tooltip.top="t('KANBAN_MACROS.ITEM.REMOVE')"
      icon="i-woot-bin"
      slate
      xs
      class="flex-shrink-0 hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
      @click="emit('remove')"
    />
  </div>
</template>
