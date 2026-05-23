<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';
import MacroItemEditor from './MacroItemEditor.vue';

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => [],
  },
  kind: {
    type: String,
    required: true,
    validator: v => ['trigger', 'condition', 'action'].includes(v),
  },
  availableTypes: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

const sectionLabel = computed(() => {
  if (props.kind === 'trigger') return t('KANBAN_MACROS.BUILDER.WHEN');
  if (props.kind === 'condition') return t('KANBAN_MACROS.BUILDER.IF');
  return t('KANBAN_MACROS.BUILDER.THEN');
});

const addButtonLabel = computed(() => {
  if (props.kind === 'trigger') return t('KANBAN_MACROS.BUILDER.ADD_TRIGGER');
  if (props.kind === 'condition')
    return t('KANBAN_MACROS.BUILDER.ADD_CONDITION');
  return t('KANBAN_MACROS.BUILDER.ADD_ACTION');
});

const emptyLabel = computed(() => {
  if (props.kind === 'trigger')
    return t('KANBAN_MACROS.BUILDER.EMPTY_TRIGGERS');
  if (props.kind === 'condition')
    return t('KANBAN_MACROS.BUILDER.EMPTY_CONDITIONS');
  return t('KANBAN_MACROS.BUILDER.EMPTY_ACTIONS');
});

const items = computed({
  get: () => props.modelValue,
  set: val => emit('update:modelValue', val),
});

const getTypeSchema = type =>
  props.availableTypes.find(entry => entry.type === type) || null;

const onTypeSelect = event => {
  const selectedType = event.target.value;
  if (!selectedType) return;
  emit('update:modelValue', [
    ...props.modelValue,
    { type: selectedType, config: {} },
  ]);
  event.target.value = '';
};

const updateItem = (index, updatedItem) => {
  const updated = [...props.modelValue];
  updated[index] = updatedItem;
  emit('update:modelValue', updated);
};

const removeItem = index => {
  const updated = props.modelValue.filter((_, i) => i !== index);
  emit('update:modelValue', updated);
};
</script>

<template>
  <div class="flex flex-col gap-3">
    <div class="flex items-center justify-between">
      <h3 class="text-sm font-semibold text-n-slate-12 flex items-center gap-2">
        <span
          class="px-2 py-0.5 rounded bg-n-alpha-2 border border-n-weak text-n-slate-10 text-xs font-medium"
        >
          {{ sectionLabel }}
        </span>
      </h3>

      <div class="flex items-center gap-2">
        <select
          class="h-8 px-3 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand cursor-pointer"
          @change="onTypeSelect"
        >
          <option value="">{{ addButtonLabel }}</option>
          <option
            v-for="typeOpt in availableTypes"
            :key="typeOpt.type"
            :value="typeOpt.type"
          >
            {{ typeOpt.label }}
          </option>
        </select>
      </div>
    </div>

    <div
      v-if="items.length === 0"
      class="py-4 text-center text-sm text-n-slate-9 border border-dashed border-n-weak rounded-lg"
    >
      {{ emptyLabel }}
    </div>

    <Draggable
      v-else
      v-model="items"
      item-key="type"
      animation="200"
      handle=".cursor-grab"
      class="flex flex-col gap-2"
    >
      <template #item="{ element, index }">
        <MacroItemEditor
          :item="element"
          :type-schema="getTypeSchema(element.type)"
          @update:item="updateItem(index, $event)"
          @remove="removeItem(index)"
        />
      </template>
    </Draggable>
  </div>
</template>
