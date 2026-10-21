# Rua dos Ventos

Hub residencial que substitui a apresentação do quintal. O identificador interno `quintal` permanece para compatibilidade com menus, conta e retorno da campanha.

- Três novas pinturas em 1536 × 1024: rua, loja e casa do professor.
- Sala e quarto reaproveitam as pinturas da abertura; entrar novamente não executa o roteiro nem concede itens.
- Cinco mapas Tiled `.tmj`, editáveis, com chão navegável, entradas, destinos e saída recíproca. Os telhados e móveis ficam fora do chão permitido.
- Casa: mãe, sala e quarto. Loja: linhas e informação sobre pipas. Professor: primeiro voo, escola, Dex e invocação. Rua: amigos, trocas, coleção, fazenda e cidade.
- O balcão usa a loja existente de linhas; não adiciona venda de criaturas nem novos preços.
- As transições exigem interação junto à entrada, conservam a conta e não escrevem progresso. O destino de retorno é a porta da qual o jogador veio.
- Arte gerada com referências das casas existentes; prompts em `PROMPTS.json`. Não foram removidos fundos por chave de cor.

Edição: abrir os mapas no Tiled mantendo a camada de imagem e os grupos `Walkable`, `Solids`, `Foreground`, `Interactions`, `Spawns`, `Exits`. As cópias das pinturas da casa são idênticas às da abertura e ficam junto dos mapas para permitir abrir o projeto diretamente no Tiled.

Validação: `street.test.mjs` verifica portais recíprocos, caminhos, áreas proibidas e imagens. `first-flight.test.mjs` percorre rua/casa/quarto/loja/professor e verifica que as visitas não escrevem na conta nem repetem a abertura. Nenhuma migração é necessária.
