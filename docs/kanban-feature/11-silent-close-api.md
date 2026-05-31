# PR11 — API Silenciosa de Encerramento (silent_close)

## Caso de uso

Automações externas (ex: n8n) precisam encerrar conversas de forma programática sem passar pelo modal de UI.

Fluxo típico: n8n recebe webhook do Chatwoot → classifica mensagem como "menção a story" (não-atendimento) → chama `silent_close` → conversa fica `resolved` + card do kanban é arquivado + classificação custom aplicada + observação registrada.

## Endpoint

```
POST /api/v1/accounts/:account_id/conversations/:id/silent_close
```

## Autenticação

Header `api_access_token` padrão do Chatwoot. Aceita user token ou account token.

## Payload

```json
{
  "classification_id": 42,
  "closing_note": "Encerrado automaticamente pelo n8n - menção a story do Instagram"
}
```

Ambos obrigatórios. `closing_note` é o campo canônico — mesmo nome usado em `set_closing_attributes` do `toggle_status`. Sem mapeamento de alias.

## Comportamento

1. Verifica se conversa está `resolved`. Se já estiver, retorna 200 com `was_already_resolved: true` sem nenhuma escrita — não altera classificação nem `closing_note` atuais, mesmo que o payload traga valores diferentes (idempotência pura).
2. Valida que `classification_id` existe e pertence à conta.
3. Valida que `closing_note` não está vazio.
4. Seta `conversation.classification_id` e `conversation.closing_note`.
5. Chama `conversation.update!(status: :resolved)`.
   - O callback `handle_kanban_status_transitions` dispara automaticamente.
   - `Kanban::CardSyncService#sync_on_resolution` move o card pra `auto_won`/`auto_lost` (se classificação for won/lost) e arquiva.
   - `record_kanban_closure` registra activity com metadata da classificação.
6. **Bypass explícito:** não chama `validate_resolution_requirements!`. Os toggles `require_classification_on_resolve` e `require_closing_note_on_resolve` (Account settings do PR4) são ignorados. A API tem seus próprios guards.

## Padrão de implementação

Ações simples de status (`toggle_status`, `mute`, `unread`, etc.) vivem como métodos em `ConversationsController` e são declaradas como `member` em `config/routes.rb`. `silent_close` segue o mesmo padrão — método novo em `ConversationsController`, junto com `toggle_status` e similares. Não cria controller separado, não cria concern.

```ruby
# config/routes.rb — dentro do member do conversations
post :silent_close
```

```ruby
# app/controllers/api/v1/accounts/conversations_controller.rb
def silent_close
  if @conversation.resolved?
    render json: { status: 'ok', conversation_id: @conversation.id,
                   was_already_resolved: true }, status: :ok
    return
  end

  classification = current_account.conversation_classifications.find_by(id: params[:classification_id])
  unless classification
    render json: { error: 'classification_id inválido ou não pertence à conta' },
           status: :unprocessable_entity
    return
  end

  if params[:closing_note].blank?
    render json: { error: 'closing_note é obrigatório' }, status: :unprocessable_entity
    return
  end

  @conversation.classification_id = classification.id
  @conversation.closing_note = params[:closing_note]
  @conversation.update!(status: :resolved)

  render json: {
    status: 'ok',
    conversation_id: @conversation.id,
    classification: classification.name,
    was_already_resolved: false
  }, status: :ok
end
```

## Respostas

**200 — encerrado com sucesso:**
```json
{
  "status": "ok",
  "conversation_id": 123,
  "classification": "story",
  "was_already_resolved": false
}
```

**200 — já estava resolved:**
```json
{
  "status": "ok",
  "conversation_id": 123,
  "was_already_resolved": true
}
```

**401** — token ausente ou inválido (tratado pelo `BaseController`).

**403** — token válido mas sem permissão na conta (tratado pelo `BaseController`).

**404** — conversa não encontrada (tratado pelo `before_action :conversation`).

**422 — payload inválido:**
```json
{ "error": "classification_id inválido ou não pertence à conta" }
```
```json
{ "error": "closing_note é obrigatório" }
```

## Por que API nova vs `toggle_status` existente

`toggle_status` só marca `resolved`, não aplica classificação num único passo sem UI. Mais importante: chama `validate_resolution_requirements!`, que bloqueia a request se os toggles de obrigatoriedade estiverem ativos — comportamento correto para UI, errado para automação. `silent_close` aplica classificação + nota + resolve + arquiva num único call, sem depender do estado dos toggles.

## Arquivos a criar/modificar

| Arquivo | Ação |
|---------|------|
| `config/routes.rb` | Adicionar `post :silent_close` no member do conversations |
| `app/controllers/api/v1/accounts/conversations_controller.rb` | Adicionar método `silent_close` |

Sem migration. Sem frontend. Sem i18n (erros em inglês técnico, consumidos por automação).

## Smoke tests

| # | Cenário | Resultado esperado |
|---|---------|-------------------|
| 1 | Sem token | 401 |
| 2 | Token inválido | 401 |
| 3 | Token válido, conta errada | 403 |
| 4 | Conversation não existe | 404 |
| 5 | `classification_id` inválido | 422 |
| 6 | `closing_note` ausente | 422 |
| 7 | Payload válido, conversa `open` | 200, conversa `resolved`, card arquivado |
| 8 | Payload válido, conversa já `resolved` | 200 com `was_already_resolved: true`, sem mudança |
| 9 | Classificação `won` | card move pra `auto_won` antes de arquivar |
| 10 | Classificação `lost` | card move pra `auto_lost` |
| 11 | Toggle `require_classification_on_resolve` ativado | API resolve normalmente (bypass) |

## Deployment

Sem migration. Aplica via Portainer `:latest` re-pull.
