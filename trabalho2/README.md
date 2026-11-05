# Trabalho Prático de PBD — Sistema de Eventos e Inscrições

> **Valor:** 7,0 pontos · **Formato:** dupla · **Entrega:** única, via SIGAA
> **Stack:** PostgreSQL + Flask + Jinja + psycopg2 + HTML/CSS

**Integrantes:** **Ricardo** e **Lucas Oliveira**

---

## 1. Visão geral

### 1.1 Objetivo
Desenvolver uma aplicação web integrada ao PostgreSQL, implementando regras de negócio no próprio banco por meio de **triggers**, **stored procedures** e **functions**.

### 1.2 Tema escolhido
**Sistema de Eventos e Inscrições** (ex.: semana acadêmica, workshops, ciclo de palestras).

O tema permite regras de negócio naturais (vagas, lista de espera, cancelamento, desconto, choque de horário), de modo que cada uma das seis rotinas tem uma finalidade real, sem criar rotinas artificiais.

### 1.3 Requisitos do enunciado

| Requisito | Mínimo exigido |
|---|---|
| Tabelas relacionadas | 5 |
| Triggers | 2 |
| Stored procedures | 2 |
| Functions | 2 |
| Constraints | PK, FK, CHECK, UNIQUE, NOT NULL, conforme pertinente |
| Aplicação web | Flask, Jinja, psycopg2, HTML e CSS |

---

## 2. Modelagem do banco de dados

### 2.1 Tabelas

| Tabela | Campos principais |
|---|---|
| `categoria` | `id` (PK), `nome` (UNIQUE, NOT NULL) |
| `local` | `id` (PK), `nome`, `capacidade` (CHECK > 0) |
| `evento` | `id` (PK), `titulo`, `categoria_id` (FK), `local_id` (FK), `data_inicio`, `data_fim`, `vagas` (CHECK > 0), `valor_base` (CHECK >= 0), `status` (`aberto` / `encerrado` / `cancelado`) |
| `participante` | `id` (PK), `nome`, `email` (UNIQUE), `tipo` (`estudante` / `professor` / `externo`) |
| `inscricao` | `id` (PK), `participante_id` (FK), `evento_id` (FK), `data_inscricao`, `status` (`confirmada` / `lista_espera` / `cancelada`), `valor_pago`. **UNIQUE** (`participante_id`, `evento_id`) |
| `log_inscricao` | `id` (PK), `inscricao_id` (FK), `status_anterior`, `status_novo`, `data_hora`, `usuario` |

### 2.2 Relacionamentos

- `categoria` 1:N `evento`
- `local` 1:N `evento`
- `participante` 1:N `inscricao`
- `evento` 1:N `inscricao`
- `inscricao` 1:N `log_inscricao`

### 2.3 Constraints adicionais

- `CHECK (data_fim > data_inicio)` em `evento`
- `CHECK` nos domínios de `status` e `tipo`
- `ON DELETE` coerente em cada FK (ex.: `RESTRICT` em `evento` → `inscricao`)

---

## 3. Rotinas do banco (as seis exigidas)

### 3.1 Resumo

| # | Rotina | Tipo | Finalidade |
|---|---|---|---|
| 1 | `trg_valida_inscricao` | Trigger (BEFORE INSERT em `inscricao`) | Bloquear inscrições inválidas |
| 2 | `trg_auditoria_inscricao` | Trigger (AFTER INSERT OR UPDATE em `inscricao`) | Registrar histórico de status |
| 3 | `sp_realizar_inscricao` | Stored procedure | Inscrever com confirmação ou lista de espera |
| 4 | `sp_cancelar_inscricao` | Stored procedure | Cancelar e promover da lista de espera |
| 5 | `fn_calcular_valor_inscricao` | Function (retorna `NUMERIC`) | Calcular valor com desconto por tipo |
| 6 | `fn_relatorio_ocupacao` | Function (retorna `TABLE`) | Indicadores de ocupação e arrecadação |

### 3.2 Detalhamento

#### Trigger 1 — `trg_valida_inscricao`
- **Regra:** impede inscrição em evento `cancelado` ou `encerrado` e em evento cujo horário conflite com outro já confirmado do mesmo participante.
- **Mecanismo:** `RAISE EXCEPTION` com mensagem clara.
- **Como verificar:** inscrever o mesmo participante em dois eventos no mesmo horário.

#### Trigger 2 — `trg_auditoria_inscricao`
- **Regra:** toda criação ou mudança de status em `inscricao` gera uma linha em `log_inscricao`.
- **Como verificar:** cancelar uma inscrição e consultar `log_inscricao`.

#### Procedure 1 — `sp_realizar_inscricao(p_participante, p_evento)`
- **Regra:** calcula o valor com `fn_calcular_valor_inscricao`. Se há vaga, grava a inscrição como `confirmada`; se não há, como `lista_espera`.
- **Como verificar:** lotar um evento de 2 vagas e inscrever uma terceira pessoa.

#### Procedure 2 — `sp_cancelar_inscricao(p_inscricao)`
- **Regra:** marca a inscrição como `cancelada`. Se ela estava confirmada, promove o primeiro da lista de espera (menor `data_inscricao`) para `confirmada`.
- **Como verificar:** cancelar uma inscrição confirmada de um evento lotado e conferir a promoção.

#### Function 1 — `fn_calcular_valor_inscricao(p_participante, p_evento)`
- **Regra:** aplica desconto conforme o tipo do participante (sugestão: estudante 50%, professor 30%, externo 0%).
- **Como verificar:** `SELECT fn_calcular_valor_inscricao(1, 2);`

#### Function 2 — `fn_relatorio_ocupacao()`
- **Regra:** para cada evento, retorna vagas, confirmados, lista de espera, percentual de ocupação e arrecadação.
- **Como verificar:** `SELECT * FROM fn_relatorio_ocupacao();`

---

## 4. Aplicação web (Flask)

### 4.1 Telas mínimas

| Tela | Integração com o banco |
|---|---|
| Listagem de eventos | `SELECT * FROM fn_relatorio_ocupacao()` |
| Cadastro de evento | `INSERT` em `evento` |
| Cadastro de participante | `INSERT` em `participante` |
| Formulário de inscrição | `CALL sp_realizar_inscricao(%s, %s)` e exibição do valor via `fn_calcular_valor_inscricao` |
| Minhas inscrições | `SELECT` em `inscricao` + botão `CALL sp_cancelar_inscricao(%s)` |
| Auditoria | `SELECT` em `log_inscricao` |

### 4.2 Boas práticas de integração

- Conexão centralizada em `db.py`, com credenciais em variáveis de ambiente (`.env`).
- `conn.commit()` em caso de sucesso e `conn.rollback()` em caso de erro.
- Capturar as exceções do psycopg2 e exibir a mensagem do `RAISE EXCEPTION` com `flash()`, deixando as triggers visíveis na interface.
- Usar sempre parâmetros (`%s`), nunca concatenação de strings (evita SQL injection).
- `CREATE PROCEDURE` e `CALL` exigem PostgreSQL 11 ou superior.

### 4.3 Estrutura de pastas

```
projeto-eventos/
├── app.py
├── db.py
├── requirements.txt
├── .env.example
├── README.md
├── sql/
│   ├── 01_schema.sql
│   ├── 02_functions.sql
│   ├── 03_procedures.sql
│   ├── 04_triggers.sql
│   ├── 05_seed.sql
│   └── 99_testes.sql
├── script_completo.sql      # junção dos arquivos de sql/
├── templates/
│   ├── base.html
│   ├── eventos.html
│   ├── inscricao.html
│   ├── minhas_inscricoes.html
│   └── auditoria.html
├── static/
│   └── style.css
└── docs/
    └── rotinas.md
```

---

## 5. Cronograma (4 semanas — adaptável ao prazo)

| Período | Atividades | Divisão sugerida |
|---|---|---|
| **Semana 1 — Base** | Fechar o tema e as regras · Desenhar o DER · Escrever `01_schema.sql` e `05_seed.sql` · Configurar repositório, ambiente virtual e conexão Flask–PostgreSQL | **A:** schema e seed · **B:** ambiente, `app.py` e `db.py` |
| **Semana 2 — Rotinas** | Implementar 2 functions, 2 procedures e 2 triggers · Testar cada uma no psql/pgAdmin com cenários de sucesso e erro · Registrar tudo em `99_testes.sql` | **A:** functions + procedure 1 · **B:** triggers + procedure 2 |
| **Semana 3 — Aplicação** | Criar rotas e templates Jinja · Integrar as rotinas (`CALL` e `SELECT`) · Tratar erros com `flash` · CSS básico | **A:** eventos e inscrições · **B:** participantes, auditoria e layout |
| **Semana 4 — Fechamento** | **Revisão cruzada** das rotinas · README e `docs/rotinas.md` · Teste do zero (banco novo → script → app) · Ensaio da apresentação · Montar o pacote e entregar no SIGAA | Os dois |

> Com prazo menor: junte as semanas 1 e 2 (modelagem + rotinas) e as semanas 3 e 4 (app + documentação). Mantenha sempre a revisão cruzada e o teste do zero.

### Marcos de controle

- [ ] Fim da semana 1: banco criado e populado, app conectando
- [ ] Fim da semana 2: seis rotinas funcionando e testadas no banco
- [ ] Fim da semana 3: todas as rotinas acionadas pela aplicação
- [ ] Fim da semana 4: pacote revisado e enviado

---

## 6. Distribuição da pontuação e foco

| Critério | Pontos | Onde investir esforço |
|---|---|---|
| Modelagem, relacionamentos e integridade | 1,0 | Constraints bem pensadas, DER claro |
| Triggers | 1,0 | Regras reais, mensagens de erro claras |
| Stored procedures | 1,0 | Várias tabelas atualizadas de forma consistente |
| Functions | 1,0 | Retornos úteis e usados pela aplicação |
| Aplicação web e integração | 1,0 | Flask + Jinja + psycopg2 funcionando de ponta a ponta |
| Apresentação e demonstração | **1,5** | Roteiro ensaiado; os dois sabem explicar tudo |
| Organização e documentação | 0,5 | README, `docs/rotinas.md`, entrega limpa |

---

## 7. Roteiro de demonstração (sugestão)

1. Apresentar o sistema e o DER (modelagem e relacionamentos).
2. Mostrar a listagem de eventos (**Function 2**).
3. Cadastrar uma inscrição de estudante e mostrar o valor com desconto (**Function 1** + **Procedure 1**).
4. Lotar um evento e inscrever mais uma pessoa → vai para a lista de espera (**Procedure 1**).
5. Tentar inscrição em evento com horário conflitante → erro exibido (**Trigger 1**).
6. Cancelar uma inscrição confirmada → o primeiro da fila é promovido (**Procedure 2**).
7. Abrir a página de auditoria e mostrar o histórico gerado (**Trigger 2**).
8. Explicar a integração Flask ↔ Jinja ↔ psycopg2 ↔ PostgreSQL.

---

## 8. Checklist de entrega (SIGAA)

- [ ] Código-fonte completo (Python, templates, estáticos)
- [ ] Script SQL completo (tabelas, constraints, triggers, procedures, functions e dados de teste)
- [ ] `README.md` com integrantes, descrição, tecnologias e instruções de execução
- [ ] Documentação das seis rotinas (`docs/rotinas.md`): finalidade, regra de negócio e como verificar
- [ ] **Pasta `.venv`/`venv` removida**
- [ ] Sem `__pycache__`, arquivos temporários ou caches
- [ ] `requirements.txt` atualizado
- [ ] Teste final do zero em uma máquina/banco limpo
- [ ] Envio **único** pelo SIGAA, dentro do prazo

---

## 9. Modelo de README

```markdown
# Sistema de Eventos e Inscrições

**Integrantes:** Nome 1, Nome 2

## Descrição
Breve descrição do sistema e das funcionalidades.

## Tecnologias
PostgreSQL, Python 3.x, Flask, Jinja, psycopg2, HTML/CSS.

## Como executar
1. Criar o banco: `createdb eventos`
2. Executar o script: `psql -d eventos -f script_completo.sql`
3. Criar o ambiente virtual e instalar dependências:
   `python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt`
4. Configurar o `.env` a partir do `.env.example`
5. Rodar a aplicação: `flask run`

## Rotinas
Ver `docs/rotinas.md`.
```

---

## 10. Modelo de documentação das rotinas (`docs/rotinas.md`)

Para cada uma das seis rotinas, preencher:

```markdown
### Nome da rotina
- **Tipo:** trigger / stored procedure / function
- **Finalidade:** ...
- **Regra de negócio:** ...
- **Tabelas envolvidas:** ...
- **Como verificar:** comando SQL e/ou passo na aplicação
- **Resultado esperado:** ...
```
