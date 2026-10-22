# Sugestões de triggers para o banco `ifbet` — PostgreSQL


Abaixo estão sugestões de triggers organizadas por finalidade, priorizando regras de negócio que fazem sentido para esse sistema. Algumas reforçam validações já feitas pelas funções e procedures; outras acrescentam regras que atualmente não estão garantidas pelo banco.

## 1. Lista de triggers sugeridas

| Nº | Tabela / evento                          | Regra de negócio                                                                |
| -- | ---------------------------------------- | ------------------------------------------------------------------------------- |
| 1  | `aposta` — `BEFORE INSERT`               | Impedir apostas com valor menor ou igual a zero.                                |
| 2  | `aposta` — `BEFORE INSERT`               | Impedir apostas com saldo insuficiente, mesmo se inseridas diretamente por SQL. |
| 3  | `aposta` — `BEFORE INSERT`               | Impedir apostas em jogos que já começaram.                                      |
| 4  | `aposta` — `BEFORE INSERT`               | Validar se os gols previstos são valores não negativos.                         |
| 5  | `aposta` — `BEFORE INSERT`               | Impedir mais de uma aposta do mesmo usuário para o mesmo jogo.                  |
| 6  | `aposta` — `AFTER INSERT`                | Descontar automaticamente o valor da aposta do saldo do usuário.                |
| 7  | `aposta` — `AFTER DELETE`                | Devolver o valor da aposta ao usuário quando ela for cancelada.                 |
| 8  | `aposta` — `BEFORE UPDATE`               | Impedir alterações indevidas em apostas já registradas.                         |
| 9  | `jogo` — `BEFORE INSERT OR UPDATE`       | Impedir que uma equipe enfrente a si mesma.                                     |
| 10 | `jogo` — `BEFORE INSERT OR UPDATE`       | Impedir resultados com gols negativos.                                          |
| 11 | `jogo` — `BEFORE UPDATE`                 | Impedir a alteração do resultado de um jogo já encerrado.                       |
| 12 | `usuario` — `BEFORE UPDATE`              | Impedir que o saldo fique negativo.                                             |
| 13 | `usuario` — `BEFORE INSERT OR UPDATE`    | Converter o e-mail para letras minúsculas.                                      |
| 14 | `campeonato` — `BEFORE INSERT OR UPDATE` | Validar o ano e impedir valores anteriores a 1900.                              |
| 15 | `jogo` — `BEFORE INSERT OR UPDATE`       | Impedir datas de jogos anteriores à data atual, se essa for a regra adotada.    |
| 16 | `aposta` — `AFTER INSERT`                | Registrar um histórico de auditoria das apostas realizadas.                     |
| 17 | `usuario` — `AFTER UPDATE`               | Registrar alterações de saldo para auditoria.                                   |
| 18 | `jogo` — `AFTER UPDATE`                  | Identificar o encerramento de um jogo e processar apostas vencedoras.           |

Observação importante: as triggers 2 e 6 não devem ser implementadas isoladamente sem planejar a interação entre elas. Como o banco já desconta o saldo nas funções `propor_aposta` e `realizar_aposta`, uma trigger que também desconte esse valor provocaria desconto duplicado. O mesmo cuidado vale para o estorno na procedure `cancelar_aposta`.;


## 2. Exemplos de implementação

A seguir, três exemplos completos, incluindo as funções que executam as triggers.

### Trigger 1 — Impedir apostas com valor inválido

```
CREATE OR REPLACE FUNCTION validar_valor_aposta()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.valor IS NULL OR NEW.valor <= 0::money THEN
        RAISE EXCEPTION
            'O valor da aposta deve ser maior que zero.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_valor_aposta
BEFORE INSERT OR UPDATE OF valor ON aposta
FOR EACH ROW
EXECUTE FUNCTION validar_valor_aposta();
```

### Trigger 2 — Impedir apostas em jogos já iniciados

```
CREATE OR REPLACE FUNCTION validar_data_aposta()
RETURNS TRIGGER AS $$
DECLARE
    var_data_hora timestamp;
BEGIN
    SELECT data_hora
    INTO var_data_hora
    FROM jogo
    WHERE id = NEW.jogo_id;

    IF var_data_hora IS NULL THEN
        RAISE EXCEPTION 'Jogo inexistente.';
    END IF;

    IF var_data_hora <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION
            'Não é permitido apostar em jogos já iniciados.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_data_aposta
BEFORE INSERT OR UPDATE OF jogo_id ON aposta
FOR EACH ROW
EXECUTE FUNCTION validar_data_aposta();
```

Esse exemplo considera que não se pode apostar a partir do horário previsto para o início da partida. Para maior rigor, também seria necessário tratar alterações no horário do jogo.

### Trigger 3 — Impedir que uma equipe jogue contra si mesma

```
CREATE OR REPLACE FUNCTION validar_equipes_jogo()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.equipe_casa_id = NEW.equipe_visitante_id THEN
        RAISE EXCEPTION
            'A equipe da casa deve ser diferente da visitante.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_equipes_jogo
BEFORE INSERT OR UPDATE OF equipe_casa_id, equipe_visitante_id
ON jogo
FOR EACH ROW
EXECUTE FUNCTION validar_equipes_jogo();
```

Essa regra complementa a validação existente na função `criar_jogo`, garantindo que ela também seja aplicada quando alguém inserir ou atualizar registros diretamente na tabela `jogo`.;

## 3. Quais eu priorizaria para uma atividade de aula?

Para trabalhar os diferentes eventos e momentos de execução das triggers, sugiro esta sequência:

- Básicas: validar valor da aposta, gols não negativos e equipes diferentes.
- Intermediárias: normalizar e-mail, impedir saldo negativo e bloquear apostas após o início do jogo.
- Avançadas: descontar saldo automaticamente, devolver valores após cancelamento e registrar auditoria.
- Desafio: processar automaticamente as apostas vencedoras quando o resultado de um jogo for informado.

Uma recomendação de modelagem: se o objetivo for garantir integridade mesmo com operações SQL diretas, as regras de validação devem ficar no banco, e as funções e procedures devem evitar duplicar os efeitos financeiros das triggers. Para operações concorrentes envolvendo saldo, também é importante proteger a atualização contra duas apostas simultâneas que tentem consumir o mesmo saldo.