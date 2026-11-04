# Casa do Kael — kit contemporâneo v1

Direção aprovada como pedido: interior dos dois pisos coerente com a fachada azul/creme, madeira clara e plantas, em 2D mangá/cartoon. A aprovação das peças finais ainda depende da revisão do dono.

`fontes/` conserva os PNGs originais gerados pela ferramenta nativa `image_gen.imagegen`, sem alteração. `prompts.json` guarda os prompts exatos e os nomes dos arquivos de origem. Nove peças novas: cama, aparador, guarda-roupa, mesa de criação, sofá, mesa de centro, mesa de jantar, banco e cozinha. TV CRT e janela são reaproveitadas da exploração desta mesma tarefa. Não houve download de arte de terceiros. As guias de volume existentes do quarto v3 e da sala v1 orientaram a projeção; a cama moderna foi a referência de estilo da família.

O kit consumido pelo jogo está em `godot/assets/campaign/casa-moderna-v1/kit.json`. Seus onze PNGs são cópias idênticas às fontes. A janela atende aos dois pisos; o banco atende às duas posições do jantar. `qa.json` registra dimensões, alfa transparente real e limites de recorte por peça. O recorte acontece somente no renderer, com escala uniforme: não há deformação para preencher largura e altura separadamente.

`house_modern.gd` constrói pisos, paredes, tapetes, porta e escadas em geometria nativa, sobre as coordenadas canônicas. A descida foi revisada após o feedback do dono: vão rebaixado, degraus claros recortados no limite do vão e guarda-corpo azul com entrada livre. A lateral da escada ascendente segue o perfil de cada degrau, sem frestas triangulares.

Conferência e capturas: `documentation/overworld/casa-kael-moderna/README.md`.
