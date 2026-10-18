# Quintal do Clube — reconstrução modular v1

Mapa de 1536×1024, 48×32 células, com as seis camadas de objetos do contrato Tiled. A cena padrão do quintal é compilada de `blockout.tmj`, `art.json` e `../quintal-kit-v1/manifest.json`. Não usa a imagem panorâmica antiga como chão; ela permanece preservada como referência de identidade.

Planta: varanda/coleção a oeste, portão para Kronasta ao norte, mesa do professor no setor oeste-central, banca de linhas a leste, plataforma de invocação no setor leste-central, expositor de carretéis a sudoeste, banco/mural dos amigos a sudeste. O centro é um pátio aberto para a chegada e o passeio. Gramado e caminhos são caminháveis, respeitando bases, árvores e limites do lote. Os pilares do portão são duas colisões independentes; o vão fica livre.

Professor e Nozinho são atores, com posições declaradas nas propriedades do mapa. Telhado, copas e portão pertencem à frente visual, separados das bases físicas. A plataforma é arte de chão, sem colisão no centro; postes, bancos, mesa, varanda e pilares possuem bases reais. Preserva `city`, `collection`, `professor`, `shop`, `summon` e `friends`, sem introduzir recompensas ou permissões.

Ateliê: http://127.0.0.1:5210/?project=quintal. O `project.json` é editável e exportável. A gravação automática desse endereço usa uma chave própria, preservando a bancada anterior do Morro. Exportar cria um pacote; integrar novas edições exige revisar os arquivos e executar o build do jogo. Não há publicação automática.

Regeração determinística dos metadados e da planta: `art/world-quintal-modular-v1/build-quintal.py`. O script só lê os PNGs originais, mede recortes e escreve JSON; não edita a arte. Prompts e auditoria de recortes estão na mesma pasta de arte.

Revisão estrutural: `http://127.0.0.1:5210/?project=quintal&revision=estrutura-v2` usa uma gravação separada para preservar edições da bancada anterior. Copas sobrepõem os galhos; muros repetem somente seu interior com escala constante; os caminhos usam contornos unidos com curvas de 24 px; o banco fica no pátio, com acesso ao sul. Executar `npm run audit:world` e seguir `tools/atelie/AUDIT-RULES.md` antes de aprovar próximas criações.

Revisão mais recente: `http://127.0.0.1:5210/?project=quintal&revision=muros-v3`. Usa a nova folha conectada `walls-v2.png`, com quatro direções e quatro quinas próprias, substituindo o muro anterior. A chave de gravação também é nova. Painel de encaixes: `http://127.0.0.1:5210/wall-audit.html`.
