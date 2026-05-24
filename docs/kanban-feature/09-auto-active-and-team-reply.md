# Fase 9 — `auto_active` e macro "Mensagem enviada pelo time"

## Objetivo

Introduzir a quarta categoria funcional de coluna (`auto_active`) e o trigger
`MessageReceivedFromTeam`, completando o ciclo automático de vai-e-vem entre
"aguardando atendimento" e "atendimento ativo".

Com este PR o fluxo automático fecha:

```
Cliente responde          Time responde
       │                        │
       ▼                        ▼
  auto_receive  ◄────────  auto_active
```

---

## 1. Modelo conceitual — 4 categorias de coluna

| `column_function` | Nome sugerido        | Papel no fluxo                                              |
|-------------------|----------------------|-------------------------------------------------------------|
| `auto_receive`    | Aguardando atendimento | Card vai pra cá automaticamente quando **cliente** responde |
| `auto_active`     | Atendimento ativo    | Card vai pra cá automaticamente quando **time** responde    |
| `no_function`     | Status manual (n)    | Colunas de processo (ex: "Orçamento enviado") — sem automação |
| `auto_won`        | Ganho / Encerrado    | Card arquivado como ganho                                   |
| `auto_lost`       | Perdido / Arquivado  | Card arquivado como perdido                                 |

> **Constraint de unicidade:** exatamente uma coluna por função automática por conta (mesmo padrão de `auto_receive`, `auto_won`, `auto_lost`). Admin escolhe qual coluna recebe cada função na UI de "Gerenciar colunas".

---

## 2. Regras de transição automática

### 2.1 Cliente envia mensagem → move pra `auto_receive`

**Trigger:** `LeadMessageReceived` (`message.incoming?`)

**Condição de guarda (nova neste PR):** o card da conversa deve estar **atualmente** em coluna com `column_function: auto_active`.

| Coluna atual do card     | O que acontece               |
|--------------------------|------------------------------|
| `auto_active`            | ✅ Move pra `auto_receive`   |
| `auto_receive`           | ⛔ Não move (já está lá)     |
| `no_function` (status)   | ⛔ Não move                  |
| `auto_won` / `auto_lost` | ⛔ Não move (card arquivado) |

### 2.2 Time responde mensagem → move pra `auto_active`

**Trigger:** `MessageReceivedFromTeam` (novo)  
Match: `event.type == :message_created` + `message.outgoing?` + `!message.private_note?`

**Condição de guarda:** o card deve estar **atualmente** em coluna com `column_function: auto_receive`.

| Coluna atual do card     | O que acontece               |
|--------------------------|------------------------------|
| `auto_receive`           | ✅ Move pra `auto_active`    |
| `auto_active`            | ⛔ Não move (já está lá)     |
| `no_function` (status)   | ⛔ Não move                  |
| `auto_won` / `auto_lost` | ⛔ Não move (card arquivado) |

---

## 3. Mudança de comportamento em relação ao PR3 — ⚠️ breaking

### Comportamento anterior (PR3)
O macro "Lead enviou mensagem" movia o card pra `auto_receive` de **qualquer** coluna
(exceto a própria `auto_receive`, pela condition `CardNotInColumnFunction`).

Isso significava: cliente respondendo de "Orçamento enviado" → card saltava pra
"Aguardando atendimento", potencialmente perdendo contexto de progresso comercial.

### Comportamento novo (este PR)
O trigger `LeadMessageReceived` ganha uma **condição de guarda implícita no próprio trigger**:
só dispara se o card está em coluna `auto_active`.

Resultado:
- Colunas de status (`no_function`) ficam "estáveis" — agente pode mover o card pra
  "Orçamento enviado" e ele permanece lá até intervenção manual.
- O ciclo automático acontece apenas entre `auto_active` ↔ `auto_receive`.

### Por que mudar no trigger e não só na condition?
A guarda no trigger é a abordagem mais econômica:
- Não precisa de nova condition class.
- Evita que o dispatcher carregue card + coluna para em seguida descartar no `matches?`.
- O trigger já tem acesso ao card via `event.card` (ou busca via conversa).

**Alternativa considerada:** nova condition `CardInColumnFunction` (oposta da existente).  
Descartada: mais código, mesmo resultado — o trigger já sabe qual card está ativo.

### Impacto em macros existentes
- Macros de sistema `system: true` têm o comportamento alterado silenciosamente (não há
  migração de dados — a lógica muda no código).
- Macros customizados de clientes com trigger `lead_message_received` também são afetados.
- **Documentar claramente no PR description e no changelog.**

---

## 4. Configuração necessária pelo admin

Este PR **não cria coluna `auto_active` automaticamente**. O admin deve:

1. Acessar **Configurações → Kanban → Gerenciar colunas**.
2. Editar a coluna que representa "em atendimento" (ex: "Em atendimento", "Atendendo agora").
3. No dropdown "Função", selecionar **"Atendimento ativo"** (novo valor).
4. Salvar.

Sem essa configuração:
- O macro "Mensagem enviada pelo time" loga um warning e não move nada.
- O trigger `LeadMessageReceived` nunca encontra um card em `auto_active` → nenhum card
  retorna automaticamente pra `auto_receive`.

Mesmo padrão das outras funções: `auto_receive`, `auto_won`, `auto_lost` também são
opt-in e exigem configuração manual.

---

## 5. Mudanças de schema

### 5.1 Migration: estender enum `column_function`

```ruby
# db/migrate/<ts>_add_auto_active_to_kanban_column_function.rb
class AddAutoActiveToKanbanColumnFunction < ActiveRecord::Migration[7.0]
  def up
    # Adiciona valor 4 ao enum (integer)
    # Cria partial unique index igual aos demais auto_*
    execute <<~SQL
      CREATE UNIQUE INDEX index_kanban_columns_on_account_id_auto_active_unique
        ON kanban_columns (account_id)
        WHERE (column_function = 4);
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_kanban_columns_on_account_id_auto_active_unique"
    # Garantir que nenhuma coluna usa valor 4 antes de reverter
    execute "UPDATE kanban_columns SET column_function = 0 WHERE column_function = 4"
  end
end
```

Nenhuma coluna nova, nenhuma renomeação — só o índice parcial. O valor `4` é adicionado
ao enum Ruby; o banco aceita automaticamente (INTEGER não tem enum nativo em Postgres).

---

## 6. Novas classes e modificações

### 6.1 `KanbanColumn` — estender enum

```ruby
enum :column_function, { no_function: 0, auto_receive: 1, auto_won: 2, auto_lost: 3, auto_active: 4 }

validate :unique_auto_active_per_account, if: :auto_active?

def self.auto_active_for(account)
  where(account: account, column_function: :auto_active).first
end
```

### 6.2 Trigger `LeadMessageReceived` — adicionar guarda de coluna

```ruby
def matches?(event)
  return false unless event.type == :message_created
  message = event.message
  return false unless message
  return false unless message.incoming?

  # NOVO (PR9): só dispara se card está em auto_active
  card = card_for(event)
  return false unless card
  card.kanban_column&.auto_active?
end
```

> `card_for(event)` é método helper já usado pelo dispatcher para buscar o card via
> `event.conversation.kanban_card`.

### 6.3 Trigger novo: `MessageReceivedFromTeam`

```ruby
# app/services/kanban/macros/triggers/message_received_from_team.rb
class Kanban::Macros::Triggers::MessageReceivedFromTeam < Kanban::Macros::Triggers::Base
  def self.key    = 'message_received_from_team'
  def self.label  = 'Mensagem enviada pelo time'
  def self.config_schema = {}

  def matches?(event)
    return false unless event.type == :message_created
    message = event.message
    return false unless message
    return false unless message.outgoing?
    return false if message.private_note?

    # Só dispara se card está em auto_receive
    card = card_for(event)
    return false unless card
    card.kanban_column&.auto_receive?
  end
end
```

**Por que filtrar `private_note?`:**  
Private notes são mensagens `outgoing` mas não chegam ao cliente. Não faz sentido
considerar "time respondeu" quando é uma nota interna. A mesma lógica se aplica às
outras partes do sistema (ex: filtros de notificação).

### 6.4 Seed: macro "Mensagem enviada pelo time"

Adicionado ao `DEFAULTS` do `Kanban::Macros::Seeder`:

```ruby
{
  name: 'Mensagem enviada pelo time',
  description: 'Move o card para a coluna de atendimento ativo quando o time responde.',
  triggers: [
    { 'type' => 'message_received_from_team', 'config' => {} }
  ],
  conditions: [
    { 'type' => 'conversation_status_is', 'config' => { 'status' => 'open' } }
  ],
  actions: [
    { 'type' => 'move_card_to_column_function', 'config' => { 'column_function' => 'auto_active' } }
  ]
}
```

Nota: não há condition `CardNotInColumnFunction` porque a guarda já está no próprio
trigger (só dispara se card está em `auto_receive`).

### 6.5 `MoveCardToColumnFunction` — suporte a `auto_active`

Atualizar `config_schema` para incluir `auto_active` nos valores válidos:

```ruby
def self.config_schema
  { column_function: { type: 'enum', values: %w[auto_receive auto_active], required: true } }
end
```

### 6.6 `CardNotInColumnFunction` — ampliar valores válidos

```ruby
def self.config_schema
  { column_function: { type: 'enum', values: %w[auto_receive auto_active] } }
end
```

### 6.7 Registro no initializer

```ruby
# config/initializers/kanban_macros.rb
Kanban::Macros::Triggers::MessageReceivedFromTeam,
```

---

## 7. Estratégia de seed para contas existentes

Utilizar **rake task one-shot** (mais seguro que migration de dados para produção):

```bash
bundle exec rails kanban:seed_team_reply_macro
```

```ruby
# lib/tasks/kanban/seed_team_reply_macro.rake
namespace :kanban do
  desc 'Seed macro "Mensagem enviada pelo time" para todas as contas'
  task seed_team_reply_macro: :environment do
    Account.find_each do |account|
      Kanban::Macros::Seeder.new(account).seed_defaults!
      print '.'
    end
    puts "\nConcluído."
  end
end
```

`seed_defaults!` já é idempotente — pode rodar múltiplas vezes sem duplicar.

Para novas contas: o `after_create_commit :seed_default_kanban_macros` no `Account`
já chama `Seeder#seed_defaults!`, que agora inclui "Mensagem enviada pelo time" no
`DEFAULTS`. Não precisa de mudança adicional.

---

## 8. Frontend — `KanbanColumnSettings.vue`

Adicionar `auto_active` ao array de opções no dropdown de função:

```js
{ value: 'auto_active', label: t('KANBAN.COLUMN_FUNCTION.AUTO_ACTIVE') }
```

### 8.1 i18n

`app/javascript/dashboard/i18n/locale/en/kanban.json`:
```json
{
  "COLUMN_FUNCTION": {
    "AUTO_ACTIVE": "Active attendance",
    "AUTO_ACTIVE_HINT": "Card moves here automatically when the team replies."
  }
}
```

`app/javascript/dashboard/i18n/locale/pt_BR/kanban.json`:
```json
{
  "COLUMN_FUNCTION": {
    "AUTO_ACTIVE": "Atendimento ativo",
    "AUTO_ACTIVE_HINT": "Card vai pra cá automaticamente quando o time responde."
  }
}
```

---

## 9. Pontos de integração

| Arquivo | Mudança |
|---|---|
| `app/models/kanban_column.rb` | Estender enum, validação `unique_auto_active_per_account`, helper `auto_active_for` |
| `db/migrate/<ts>_add_auto_active_to_kanban_column_function.rb` | Índice parcial único |
| `app/services/kanban/macros/triggers/lead_message_received.rb` | Adicionar guarda `auto_active?` |
| `app/services/kanban/macros/triggers/message_received_from_team.rb` | **Novo** |
| `app/services/kanban/macros/seeder.rb` | Adicionar "Mensagem enviada pelo time" ao `DEFAULTS` |
| `app/services/kanban/macros/actions/move_card_to_column_function.rb` | Ampliar `config_schema` |
| `app/services/kanban/macros/conditions/card_not_in_column_function.rb` | Ampliar `config_schema` |
| `config/initializers/kanban_macros.rb` | Registrar `MessageReceivedFromTeam` |
| `lib/tasks/kanban/seed_team_reply_macro.rake` | **Novo** — seed one-shot |
| `KanbanColumnSettings.vue` | Adicionar opção `auto_active` |
| `en/kanban.json` e `pt_BR/kanban.json` | Chaves `AUTO_ACTIVE` e `AUTO_ACTIVE_HINT` |

---

## 10. Trade-offs e decisões não óbvias

### A. Guarda no trigger vs. condition explícita
A guarda de "card deve estar em `auto_active`" foi implementada diretamente no `matches?`
do trigger em vez de criar uma condition separada `CardInColumnFunction`. Motivo:
- Trigger e condition têm semânticas diferentes: trigger é "quando o evento aconteceu";
  condition é "se o estado atual satisfaz". A guarda de coluna é um pré-requisito do
  próprio trigger fazer sentido — mais semântico ficar no trigger.
- Menos classes, menos registro, menos configuração pra entender.

### B. Breaking change no `LeadMessageReceived`
Aceita conscientemente. O comportamento anterior (mover de qualquer coluna) criava
problemas UX (agente move card pra "Orçamento enviado", cliente responde, card volta).
A guarda é necessária para que o ciclo automático seja previsível.

### C. `private_note?` excluído do `MessageReceivedFromTeam`
Notes internas não chegam ao cliente — não caracterizam "resposta do time" do ponto de
vista do lead. Excluir evita que agentes discutindo internamente (via notes) movam cards
inadvertidamente.

### D. Rake task vs. migration de dados
Rake task preferida pra seed porque:
- Pode ser executada após deploy sem janela de manutenção.
- Falha visível (output no terminal/CI); migration de dados falha silenciosamente em
  alguns setups de CD.
- Pode ser re-executada sem efeito colateral (idempotência garantida pelo `Seeder`).

### E. `auto_active` como valor 4 no enum
Segue a sequência natural. Valores 0–3 já usados; 4 é o próximo. Não há necessidade de
re-numerar.

---

## 11. Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Admin sem coluna `auto_active` configurada — time responde, nada acontece | Warning no log; macro silenciosamente skipped. Comportamento esperado (igual às demais funções sem configuração). |
| Breaking change no `LeadMessageReceived` afeta clientes com macros customizados | Documentado no changelog e PR description. Impacto: macros customizados com esse trigger param de mover de colunas `no_function` — comportamento mais correto. |
| Loop: time responde → move pra `auto_active` → "mensagem enviada" dispara de novo? | Não: o trigger só dispara se card está em `auto_receive`; ao mover pra `auto_active`, o trigger não dispara mais pra esse evento. |
| Mensagem automática de bot (outgoing, não private) dispara o trigger | Bots em Chatwoot criam mensagens `outgoing`. Se bot responder enquanto card está em `auto_receive`, card vai pra `auto_active`. Aceitável no MVP — admin pode desabilitar o macro se necessário. |
