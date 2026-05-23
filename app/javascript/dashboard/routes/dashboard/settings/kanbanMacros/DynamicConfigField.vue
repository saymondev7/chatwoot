<script setup>
import { computed } from 'vue';

const props = defineProps({
  fieldSchema: {
    type: Object,
    required: true,
  },
  modelValue: {
    type: [String, Number, Boolean],
    default: null,
  },
  fieldKey: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['update:modelValue']);

const humanize = key =>
  key.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());

const label = computed(
  () => props.fieldSchema.label || humanize(props.fieldKey)
);

const inputType = computed(() => {
  switch (props.fieldSchema.type) {
    case 'integer':
    case 'number':
      return 'number';
    case 'boolean':
      return 'checkbox';
    default:
      return 'text';
  }
});

const isEnum = computed(() => props.fieldSchema.type === 'enum');
const isBoolean = computed(() => props.fieldSchema.type === 'boolean');

const enumOptions = computed(() => props.fieldSchema.values || []);

const isRequired = computed(() => props.fieldSchema.required === true);

const min = computed(() => props.fieldSchema.min ?? undefined);
const max = computed(() => props.fieldSchema.max ?? undefined);

const onInput = event => {
  emit('update:modelValue', event.target.value);
};

const onNumberInput = event => {
  emit('update:modelValue', Number(event.target.value));
};

const onCheckboxChange = event => {
  emit('update:modelValue', event.target.checked);
};

const onSelectChange = event => {
  emit('update:modelValue', event.target.value);
};
</script>

<template>
  <div class="flex flex-col gap-1">
    <label class="text-sm font-medium text-n-slate-12">
      {{ label }}
      <span v-if="isRequired" class="text-n-ruby-9 ml-0.5">*</span>
    </label>

    <p v-if="fieldSchema.description" class="text-xs text-n-slate-10 -mt-0.5">
      {{ fieldSchema.description }}
    </p>

    <!-- Enum → select -->
    <select
      v-if="isEnum"
      :value="modelValue"
      :required="isRequired"
      class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
      @change="onSelectChange"
    >
      <option value="" disabled :selected="!modelValue">—</option>
      <option
        v-for="opt in enumOptions"
        :key="opt"
        :value="opt"
        :selected="modelValue === opt"
      >
        {{ opt }}
      </option>
    </select>

    <!-- Boolean → checkbox -->
    <input
      v-else-if="isBoolean"
      type="checkbox"
      :checked="modelValue"
      :required="isRequired"
      class="cursor-pointer"
      @change="onCheckboxChange"
    />

    <!-- Number -->
    <input
      v-else-if="inputType === 'number'"
      type="number"
      :value="modelValue"
      :required="isRequired"
      :min="min"
      :max="max"
      class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-brand"
      @input="onNumberInput"
    />

    <!-- String (default) -->
    <input
      v-else
      type="text"
      :value="modelValue"
      :required="isRequired"
      class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-brand"
      @input="onInput"
    />
  </div>
</template>
