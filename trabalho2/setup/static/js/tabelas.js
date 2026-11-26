
document.addEventListener("DOMContentLoaded", () => {

    // Localizando as tabelas da página
    const tabelas = document.querySelectorAll(".tabela");

    tabelas.forEach((tabela) => {

        const corpo = tabela.querySelector("tbody");
        const cabecalhos = tabela.querySelectorAll("thead th");

        if (!corpo) return;

        // Verificando se a pesquisa já existe
        if (tabela.parentElement.previousElementSibling?.classList.contains("tabela-pesquisa")) {
            return;
        }

        // Criando o campo de pesquisa
        const container = document.createElement("div");
        container.classList.add("tabela-pesquisa");

        const pesquisa = document.createElement("input");
        pesquisa.type = "search";
        pesquisa.placeholder = "Pesquisar na tabela...";
        pesquisa.classList.add("tabela-pesquisa__campo");

        container.appendChild(pesquisa);

        tabela.parentElement.before(container);

        // Filtrando os registros
        pesquisa.addEventListener("input", () => {

            const termo = pesquisa.value.toLowerCase().trim();
            const linhas = corpo.querySelectorAll("tr");

            linhas.forEach((linha) => {

                const conteudo = linha.textContent.toLowerCase();

                linha.hidden = !conteudo.includes(termo);

            });

        });

        // Ordenando as colunas
        cabecalhos.forEach((cabecalho, indice) => {

            cabecalho.classList.add("tabela-ordenavel");

            cabecalho.addEventListener("click", () => {

                const linhas = Array.from(corpo.querySelectorAll("tr"));

                const ordemAtual = cabecalho.dataset.ordem || "asc";
                const novaOrdem = ordemAtual === "asc" ? "desc" : "asc";

                cabecalhos.forEach((item) => {
                    delete item.dataset.ordem;
                });

                cabecalho.dataset.ordem = novaOrdem;

                linhas.sort((a, b) => {

                    const valorA = a.cells[indice].textContent.trim().toLowerCase();
                    const valorB = b.cells[indice].textContent.trim().toLowerCase();

                    const comparacao = valorA.localeCompare(valorB, "pt-BR", {
                        numeric: true,
                        sensitivity: "base"
                    });

                    return novaOrdem === "asc" ? comparacao : -comparacao;

                });

                linhas.forEach((linha) => corpo.appendChild(linha));

            });

        });

    });

});

