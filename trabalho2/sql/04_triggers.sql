-- 1. trg_valida_inscricao
CREATE TRIGGER trg_valida_inscricao
BEFORE INSERT
ON inscricao
FOR EACH ROW
EXECUTE FUNCTION fn_validar_inscricao();

-- 2. trg_auditoria_inscricao
CREATE TRIGGER trg_auditoria_inscricao
AFTER INSERT OR UPDATE
ON inscricao
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_inscricao();