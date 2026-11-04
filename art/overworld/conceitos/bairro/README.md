# PIP-84 — Rua dos Ventos: estudo de acabamento

Acabamento visual aprovado pelo responsável nesta conversa: “Gostei muito desse conceito”. A aprovação permite produzir a família modular; não aprova automaticamente encaixes, colisões, interiores ou integração final. A imagem não é um mapa jogável nem substitui a planta.

## Revisão visual

`rua-estudo-v2.png` diferencia a residência creme de Kael, o ateliê coral do Sr. Assis e a loja com pipas expostas. Telhados completos, reboco, esquadrias azuis, fios e jardins seguem a linguagem própria da prancha do projeto. O primeiro estudo permanece em `fontes/rua-estudo-v1.png`.

A segunda geração retirou a aparência de comércio da casa central e acrescentou limites de vegetação aos canteiros. A trilha inferior para o parque permanece aberta. Ainda há diferenças entre o estudo e a planta: distância entre edifícios, extensão dos jardins, posições dos bancos e limites de calçada. A arte não passou pelo critério de alinhamento de 4 px. Esses desvios não autorizam mover eventos, colisões ou a planta para acomodar a imagem.

## Fonte técnica

`brief.json` é derivado da planta revisada, com hash, cinco materiais, sete pares de transição, pegadas, eventos e centros das três portas. `registro-geometrico.svg` mostra esses pontos sobre a referência oficial. Regenerar: `node tools/overworld/brief_bairro.mjs`.

`revisao.html` permite alternar estudo, planta e sobreposição das pegadas. A sobreposição é diagnóstica e evidencia desalinhamentos; não declara encaixe validado.

## Produção seguinte

O pedido B de `art/overworld/ESPECIFICACAO-MAPAS.md` começa com “Agora transforme o conceito aprovado”. A revisão solicitada aqui é somente do acabamento visual. Depois dela, produzir peças separadas e posicioná-las nas coordenadas do contrato: 20 pisos 64×32, 112 transições de cantos, três fachadas com portas ancoradas, mural, bancada e detalhes do bairro. Bancos, postes e vegetação devem reutilizar a família comum da PIP-83. Não recortar o estudo inteiro e usá-lo como fundo de navegação.

A imagem gerada é fonte de direção artística, não geometria autoritativa. O tamanho exportado da referência é 5088×2704; o estudo tem resolução própria registrada em `fontes/proveniencia.json`. A aprovação deste estudo não encerra a PIP-84, aprova interiores ou publica alterações.

Nenhuma suíte de testes, build de jogo ou alteração de runtime foi executada nesta etapa de conceito. Os únicos comandos de produção leram as plantas e escreveram os documentos de revisão.
