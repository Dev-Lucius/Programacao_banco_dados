
document.addEventListener("DOMContentLoaded", () => {

    // Fechar mensagens automaticamente
    const mensagens = document.querySelectorAll(".flash");

    mensagens.forEach((mensagem) => {

        setTimeout(() => {
            mensagem.classList.add("flash--ocultando");

            setTimeout(() => {
                mensagem.remove();
            }, 300);

        }, 4000);

    });


    // Confirmar ações importantes
    const botoes = document.querySelectorAll("[data-confirm]");

    botoes.forEach((botao) => {

        botao.addEventListener("click", (evento) => {

            const mensagem = botao.dataset.confirm;

            if (!confirm(mensagem)) {
                evento.preventDefault();
            }

        });

    });

});

