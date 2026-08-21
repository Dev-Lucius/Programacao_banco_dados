/*
Crie uma função nome_jogo(jogo_id) que retorne uma string no formato:
- SAO PAULO DE RG x RIO GRANDE
*/
CREATE OR REPLACE FUNCTION nome_jogo(var_jogo_id integer) RETURNS text AS
$$
DECLARE
    resultado_casa text;
    resultado_visitante text;
BEGIN
    SELECT nome FROM equipe JOIN jogo ON equipe.id = jogo.equipe_casa_id WHERE jogo.id = var_jogo_id INTO resultado_casa;
    
    SELECT nome FROM equipe JOIN jogo ON equipe.id = jogo.equipe_visitante_id WHERE jogo.id = var_jogo_id INTO resultado_visitante;
    
    RETURN resultado_casa || ' x ' || resultado_visitante;
END;
$$ LANGUAGE 'plpgsql';
