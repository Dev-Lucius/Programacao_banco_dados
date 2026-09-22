/*
 * IFBet - melhorias opcionais de interface.
 * Sem este arquivo o site continua funcionando: os campos são <input type="number">.
 */
(() => {
  // 1) Botões − e + junto de cada campo de placar (aparecem só com JavaScript ativo)
  document.querySelectorAll('.placar').forEach((bloco) => {
    const campo = bloco.querySelector('input');
    const menos = bloco.querySelector('[data-passo="-1"]');
    const mais = bloco.querySelector('[data-passo="1"]');
    if (!campo || !menos || !mais) return;

    menos.hidden = false;
    mais.hidden = false;

    const minimo = Number(campo.min || 0);
    const maximo = Number(campo.max || 99);

    const mudar = (passo) => {
      const atual = parseInt(campo.value, 10) || 0;
      campo.value = Math.min(maximo, Math.max(minimo, atual + passo));
    };
    menos.addEventListener('click', () => mudar(-1));
    mais.addEventListener('click', () => mudar(1));
  });

  // 2) Evita enviar a mesma aposta duas vezes com um clique duplo
  const rotuloOriginal = new WeakMap();
  document.querySelectorAll('form.palpite').forEach((form) => {
    form.addEventListener('submit', () => {
      const botao = form.querySelector('button[type="submit"]');
      if (!botao) return;
      rotuloOriginal.set(botao, botao.textContent);
      botao.disabled = true;
      botao.textContent = 'Enviando…';
    });
  });

  // Voltar pelo histórico do navegador: reativa os botões
  window.addEventListener('pageshow', (evento) => {
    if (!evento.persisted) return;
    document.querySelectorAll('form.palpite button[type="submit"]').forEach((botao) => {
      botao.disabled = false;
      botao.textContent = rotuloOriginal.get(botao) || 'Apostar';
    });
  });
})();