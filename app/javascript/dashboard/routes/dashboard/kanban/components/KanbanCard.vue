<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  card: { type: Object, required: true },
});

const emit = defineEmits(['edit', 'delete']);

useI18n();

const contactInitials = computed(() => {
  const name = props.card.contact?.name || '?';
  return name
    .split(' ')
    .slice(0, 2)
    .map(n => n[0])
    .join('')
    .toUpperCase();
});

const formattedValue = computed(() => {
  if (props.card.potential_value == null) return null;
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(props.card.potential_value);
});
</script>

<template>
  <div
    class="relative bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 p-3 cursor-pointer hover:shadow-md transition-shadow group"
    :class="card.unread_count > 0 ? 'border-l-2 border-l-red-500' : ''"
    @click="emit('edit', card)"
  >
    <!-- Badge de mensagens não lidas (PR8) -->
    <span
      v-if="card.unread_count > 0"
      class="absolute -top-1.5 -right-1.5 min-w-[1.1rem] h-[1.1rem] bg-red-500 text-white text-[0.6rem] font-bold rounded-full flex items-center justify-center px-0.5 leading-none shadow-sm pointer-events-none"
    >
      {{ card.unread_count >= 10 ? '9+' : card.unread_count }}
    </span>
    <div class="flex items-start justify-between gap-2">
      <!-- Avatar + Nome -->
      <div class="flex items-center gap-2 min-w-0">
        <div
          v-if="card.contact?.avatar_url"
          class="w-8 h-8 rounded-full flex-shrink-0 bg-cover bg-center"
          :style="{ backgroundImage: `url(${card.contact.avatar_url})` }"
        />
        <div
          v-else
          class="w-8 h-8 rounded-full flex-shrink-0 bg-woot-500 text-white text-xs font-semibold flex items-center justify-center"
        >
          {{ contactInitials }}
        </div>
        <div class="min-w-0">
          <p
            class="text-sm font-medium text-slate-800 dark:text-slate-100 truncate"
          >
            {{ card.contact?.name }}
          </p>
          <p
            v-if="card.contact?.phone_number"
            class="text-xs text-slate-500 dark:text-slate-400 truncate"
          >
            {{ card.contact.phone_number }}
          </p>
          <p
            v-if="card.conversation?.display_id"
            class="text-xs text-n-slate-9"
          >
            #{{ card.conversation.display_id }}
          </p>
        </div>
      </div>

      <!-- Botão excluir (aparece no hover) -->
      <button
        class="p-1 rounded text-slate-400 opacity-0 group-hover:opacity-100 transition-opacity hover:text-red-500 hover:bg-slate-100 dark:hover:bg-slate-700 flex-shrink-0"
        :title="$t('KANBAN.CARD.DELETE')"
        @click.stop="emit('delete', card)"
      >
        <fluent-icon icon="delete" size="14" />
      </button>
    </div>

    <!-- Valor potencial -->
    <div v-if="formattedValue" class="mt-2">
      <span class="text-xs font-semibold text-green-600">{{
        formattedValue
      }}</span>
    </div>

    <!-- Notas -->
    <p
      v-if="card.notes"
      class="mt-2 text-xs text-slate-500 dark:text-slate-400 line-clamp-2"
    >
      {{ card.notes }}
    </p>
  </div>
</template>
