# Recortes para o galpão — versão 1

Geração pelo imagegen integrado, usando os designs aprovados como referência: `art/pipa-tv-competidores-v4/gollia-conceito-v4.png` e `art/creatures/pipa-dragao/quimico-b-v1/prancha.png`. Não são personagens novos nem substituem as pranchas de identidade. Poses novas ainda são rascunhos de integração.

Direção solicitada: mangá 2D simples, contorno fino, cores chapadas e uma sombra. Gollia mantém a mecha azul, corpo robusto, polo com faixa de onda e carretel azul; foi adaptada a uma pose chibi sudeste. Pipa-Dragão mantém pele cinza-lilás, manchas ameixa, olhos âmbar, reservatório e tubos verdes, símbolo de radiação, vela com varetas e rabiola ocre. Primeiro recorte recebeu uma segunda passagem para simplificar sombras e preservar transparência. Pixels RGB em áreas com alpha zero podem aparecer coloridos em visualizadores que ignoram alpha; a composição nativa foi conferida.

`*-source.png`: saídas originais preservadas. `tools/package-warehouse-assets.py`: recorte pela caixa do alpha significativo, normalização Lanczos e preservação do canal alpha; nenhuma remoção por chave de cor. `manifest.json` registra dimensões, fonte e orientação. PNGs de runtime em `godot/assets/campaign/warehouse-v1/`; textura linear conforme o consumidor.

Um frame por asset. A mesma pose da criatura serve à apresentação grande e à forma reduzida, por escala; ainda não há desenho de transformação, mudança anatômica animada, rig nem animações exclusivas de ataque/dano. Os estados do atlas apontam explicitamente para a pose estática. A cena usa planos ilustrados, duas amarras temporárias desenhadas pelo código e duas luzes separadas para sugerir a libertação. Retalho e Tyler reutilizam recortes existentes. Não afirmar que isso é uma cinemática final.

Agulha: ícone SVG autorado no código, sem imagem externa. Sua entrega é persistente; a mecânica de desmontar/remontar ainda não está implementada. Não há nova rabiola colecionável da Pipa-Dragão, captura ou XP repetível nesta sequência.
