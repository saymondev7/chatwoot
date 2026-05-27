# Fase 10 — Badge de mensagens não lidas no card do kanban (PR8)

## Objetivo

Exibir no card do kanban um badge visual (bolinha vermelha com contador) quando a conversa
associada tem mensagens incoming que o agente **atribuído** ainda não leu. Acompanha PR7
(`auto_active` + macro "Mensagem enviada pelo time") — os dois são deployados juntos.

---

## 1. Critério de "não lida"

**Definição:** mensagem incoming (do contato, `message_type: 0, private: false`) criada
**após** `conversations.assignee_last_seen_at` do agente atribuído à conversa.

Método adicionado em `Conversation` (ver Seção 6):

```ruby
def assignee_unread_incoming_messages
  assignee_unread_messages.where(account_id: account_id).incoming
end
```

`assignee_unread_messages` retorna mensagens criadas após `assignee_last_seen_at`.
`.incoming` filtra `message_type = 0` — exclui automaticamente outgoing e private notes
(private notes têm `message_type: outgoing` no Chatwoot).

**Por que `assignee_last_seen_at` e não `agent_last_seen_at`:**

| Situação | `agent_last_seen_at` | `assignee_last_seen_at` |
|---|---|---|
| Admin abre conversa do agente A "pra dar uma olhada" | ✅ atualiza — badge do agente A zeraria incorretamente | ❌ não atualiza — badge do agente A preservado |
| Agente A (assignee) abre a conversa | ✅ atualiza | ✅ atualiza — badge zera corretamente |

Conclusão: somente `assignee_last_seen_at` reflete o que o agente **responsável** viu.

---

## 2. Como o badge incrementa (mensagem nova)

**Canal:** ActionCable — evento `message_created`.

O payload do evento já carrega `conversation.unread_count` (baseado em
`unread_incoming_messages`, que usa `agent_last_seen_at`). **Esse valor não pode ser
usado diretamente** para o badge do kanban, pois usa a coluna errada.

**Estratégia adotada:** o kanban ouve o evento `message_created` via emitter/bus, filtra
mensagens incoming não-private, e quando encontra um card no store cujo `conversation_id`
bate com a mensagem, incrementa `card.unread_count += 1`.

```
ActionCable → BUS_EVENTS.NEW_MESSAGE
  → kanban listener (em KanbanBoard.vue ou composable dedicado)
  → message.message_type == 0 && !message.private && message.conversation_id presente?
  → encontra card no store por conversation_id
  → commit('kanban/INCREMENT_CARD_UNREAD', conversationId)
```

**Por que incrementar localmente em vez de re-fetch do backend:**
- Re-fetch do board inteiro a cada mensagem seria pesado.
- Incremento local é instantâneo e correto — apenas mensagens incoming não-private chegam
  via `message_created`.

---

## 3. Como o badge zera

**Canal:** REST + commit local no store kanban.

**Fluxo:**
1. Agente abre o `KanbanCardModal` de um card com `unread_count > 0`.
2. No `onMounted` do modal, o frontend chama
   `POST /api/v1/accounts/:account_id/conversations/:conv_id/update_last_seen`.
3. O controller atualiza `assignee_last_seen_at = now` (se o usuário atual for o assignee)
   ou `agent_last_seen_at = now` (caso contrário — sem efeito no badge).
4. O frontend faz commit local: `card.unread_count = 0` no store kanban.
5. Não há broadcast ActionCable para essa operação — `update_columns` bypassa callbacks.

**Por que REST e não ActionCable para a zeragem:**

O Chatwoot usa `update_columns` no `update_last_seen` (bypassa callbacks e callbacks de
ActiveRecord). Criar um evento ActionCable exclusivo para isso implicaria mexer em código
upstream para adicionar um broadcast manual — invasivo e frágil em rebases futuros.
REST + commit local segue o mesmo padrão do Chatwoot nativo (veja
`messageReadActions.js` → `UPDATE_MESSAGE_UNREAD_COUNT` mutation com delay de 4s).

**Risco de dessincronia aceito:** se o agente ler a conversa em outro dispositivo/aba
(via view de conversas nativa), o board kanban não atualiza em tempo real — atualizaria
apenas no próximo `fetchBoard`. Caso raro; aceito no MVP.

**Apenas o assignee zera:** se `current_user != conversation.assignee`, o controller
atualiza só `agent_last_seen_at` e o badge permanece para o assignee.

---

## 4. Performance — sem N+1

**Problema:** com 200 cards no board, chamar
`card.conversation.assignee_unread_incoming_messages.count` dentro do loop do jbuilder
gera 200 queries SQL.

**Solução: 1 query agregada antes do loop do jbuilder.**

```ruby
# No jbuilder show.json.jbuilder, antes do json.columns do |column| ...
conv_ids = board_cards_by_column.values.flatten.map(&:conversation_id).compact

unread_counts = if conv_ids.any?
  Message
    .joins(:conversation)
    .where(conversations: { id: conv_ids })
    .where(message_type: 0, private: false)
    .where(
      'messages.created_at > conversations.assignee_last_seen_at
       OR conversations.assignee_last_seen_at IS NULL'
    )
    .group('conversations.id')
    .count
else
  {}
end
```

No partial `_card.json.jbuilder`, o campo é:
```ruby
json.unread_count unread_counts[card.conversation_id].to_i
```

**Resultado:** 1 query para todo o board, independente do número de cards. O hash
`unread_counts` é passado ao partial via variável local.

---

## 5. Visual

### 5.1 Badge (contador)

- Bolinha vermelha com número no **canto superior direito** do card.
- Aparece apenas quando `card.unread_count > 0`.
- Se `unread_count >= 10`, exibe `9+`.

```html
<!-- Canto superior direito do card -->
<span
  v-if="card.unread_count > 0"
  class="absolute -top-1.5 -right-1.5 min-w-[1.1rem] h-[1.1rem] bg-red-500 text-white
         text-[0.6rem] font-bold rounded-full flex items-center justify-center px-0.5
         leading-none shadow-sm"
>
  {{ card.unread_count >= 10 ? '9+' : card.unread_count }}
</span>
```

### 5.2 Borda esquerda destacada

Quando `unread_count > 0`, a borda esquerda do card recebe destaque sutil:

```html
<div
  :class="[
    'relative bg-white dark:bg-slate-800 rounded-lg border border-slate-200 ...',
    card.unread_count > 0
      ? 'border-l-2 border-l-red-500'
      : ''
  ]"
>
```

### 5.3 Aparece em

Todas as colunas onde o card é visível — `auto_receive`, `auto_active`, `no_function`.
Não se aplica a cards arquivados (`auto_won` / `auto_lost`) porque eles já são excluídos
do board pelo scope `.active` (PR6).

---

## 6. Arquivos modificados

### 6.1 `app/models/conversation.rb` — método novo

```ruby
# Custom: adicionado pelo fork pra o badge de mensagens não lidas no kanban (PR8)
# Ref: docs/kanban-feature/10-unread-message-badge.md
def assignee_unread_incoming_messages
  assignee_unread_messages.where(account_id: account_id).incoming
end
```

> O comentário facilita identificação em futuros rebases com upstream do Chatwoot.

### 6.2 `app/views/api/v1/accounts/kanban/boards/show.json.jbuilder`

Adicionar a query agregada de `unread_counts` antes do loop de colunas (ver Seção 4).
Alterar a chamada ao partial para passar `unread_counts` como local.

### 6.3 `app/views/api/v1/accounts/kanban/cards/_card.json.jbuilder`

Adicionar `json.unread_count unread_counts[card.conversation_id].to_i`.

O partial já recebe `card` como local; `unread_counts` precisa ser adicionado como
segundo local na chamada `json.partial!` do jbuilder do board.

### 6.4 `app/javascript/dashboard/store/modules/kanban/mutations.js`

Adicionar duas mutations:

```js
INCREMENT_CARD_UNREAD(state, conversationId) {
  // Encontra o card no estado por conversation_id, incrementa unread_count
},

CLEAR_CARD_UNREAD(state, cardId) {
  // Zera unread_count do card
},
```

### 6.5 `app/javascript/dashboard/store/modules/kanban/actions.js`

Adicionar action `clearCardUnread({ commit }, cardId)` que:
1. Chama `ConversationApi.markMessageRead({ id: conversationId })` (REST).
2. Faz `commit('CLEAR_CARD_UNREAD', cardId)`.

### 6.6 `app/javascript/dashboard/routes/dashboard/kanban/components/KanbanBoard.vue`

Adicionar listener de `message_created` via emitter/bus:

```js
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

onMounted(() => {
  store.dispatch('kanban/fetchBoard');
  emitter.on(BUS_EVENTS.NEW_MESSAGE, handleNewMessage);
});

onUnmounted(() => {
  emitter.off(BUS_EVENTS.NEW_MESSAGE, handleNewMessage);
});

function handleNewMessage(message) {
  if (message.message_type !== 0 || message.private) return; // só incoming não-private
  const conversationId = message.conversation_id;
  if (!conversationId) return;
  store.commit('kanban/INCREMENT_CARD_UNREAD', conversationId);
}
```

### 6.7 `app/javascript/dashboard/routes/dashboard/kanban/components/KanbanCardModal.vue`

Adicionar chamada `update_last_seen` no `onMounted`:

```js
onMounted(async () => {
  // ... código existente ...
  if (props.card.conversation_id) {
    await store.dispatch('kanban/clearCardUnread', {
      cardId: props.card.id,
      conversationId: props.card.conversation_id,
    });
  }
});
```

### 6.8 `app/javascript/dashboard/routes/dashboard/kanban/components/KanbanCard.vue`

Adicionar `class="relative"` no container raiz e o badge + borda condicional (ver Seção 5).

---

## 7. Edge cases

| Situação | Comportamento |
|---|---|
| Card sem `conversation_id` | `unread_counts[nil].to_i == 0` → badge não aparece |
| `assignee_last_seen_at` nulo | Query retorna todas as mensagens como não lidas (`IS NULL` branch na WHERE) |
| Mensagem outgoing | `message_type != 0` → não entra na query, não incrementa no listener |
| Private note | `private: true` → excluído pela `WHERE private = false` na query, e pelo listener (`message.private` check) |
| Card em `auto_won`/`auto_lost` | Não está no board (scope `.active` filtra arquivados) → não afetado |
| Agente não-assignee abre o modal | `update_last_seen` atualiza só `agent_last_seen_at`; `assignee_last_seen_at` preservado; badge permanece para o assignee |
| Dois agents abrem o mesmo card simultaneamente | Último `clearCardUnread` vence no store local; backend é atualizado por ambos sem conflito |

---

## 8. Trade-offs e decisões não óbvias

### A. Incremento local em vez de re-fetch

Re-fetch do board a cada `message_created` seria O(n) queries por mensagem. O incremento
local é O(1) e correto para o caso de uso principal (mensagem incoming nova = +1 no card).
Dessincronia possível: mensagem deletada ou conversation_id não encontrado no board
(card não existe ou card arquivado) → listener descarta silenciosamente.

### B. `unread_counts` como variável local do jbuilder

Jbuilder permite passar locals via `json.partial! path, locals`. O partial `_card`
recebe `card:` e `unread_counts:`. Alternativa seria computar no model (método no
`KanbanCard`) mas isso exigiria join em cada instância — pior que a query agregada.

### C. Delay de 4s no `markMessageRead` nativo

O `messageReadActions.js` do Chatwoot usa `setTimeout(..., 4000)` para commitar o zero
no store de conversas (evita flash visual durante animação de scroll). No kanban, o
zero é imediato — o modal já está aberto, não há scroll de mensagens. O delay não se
aplica.

### D. `BUS_EVENTS.NEW_MESSAGE` já existe

O Chatwoot já emite `BUS_EVENTS.NEW_MESSAGE` quando chega `message_created` via
ActionCable. Não é necessário criar evento novo — apenas ouvir em `KanbanBoard.vue`.
Verificar a constante exata em `shared/constants/busEvents.js` antes de implementar.

---

## 9. Sequência de deploy (junto com PR7)

1. Merge PR7 + PR8 em `develop`.
2. Deploy em produção (Portainer `:latest`).
3. Rodar rake task do PR7: `bundle exec rails kanban:seed_team_reply_macro`.
4. Admin configura coluna `auto_active` ("Atendimento ativo") via Gerenciar colunas.
5. Badge começa a funcionar imediatamente após deploy — sem migration, sem seed adicional.
