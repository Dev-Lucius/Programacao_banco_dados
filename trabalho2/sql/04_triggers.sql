\encoding UTF8
-- 1. trg_valida_inscricao
DROP TRIGGER IF EXISTS trg_valida_inscricao ON inscricao;
CREATE TRIGGER trg_valida_inscricao
BEFORE INSERT OR UPDATE OF evento_id, participante_id, status
ON inscricao
FOR EACH ROW
EXECUTE FUNCTION fn_validar_inscricao();

-- 2. trg_auditoria_inscricao
CREATE TRIGGER trg_auditoria_inscricao
AFTER INSERT OR UPDATE
ON inscricao
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_inscricao();
