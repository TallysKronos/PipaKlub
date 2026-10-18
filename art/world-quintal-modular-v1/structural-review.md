# Revisão estrutural · 18/10/2026

Correção da planta anterior, que tinha copas quase separadas dos troncos, vãos entre módulos verticais, escala variável no último segmento horizontal, piso retangular sem curvas e banco encoberto por árvore.

- Copas com âncora inferior explícita e sobreposição de aproximadamente 19 px sobre troncos de 45 px; mesmo apoio de profundidade nas duas partes.
- Muros usam janelas interiores do atlas, sem terminais e margens transparentes. Escala constante: 64 px na horizontal e 24×96 px na vertical. Últimos segmentos sobrepõem sem encolher.
- Terreno traça a união dos retângulos de cada material/piso. Curvas de 24 px em quinas internas e externas, com teste de junções, buracos e ilhas diagonais. Chão cacheado no renderizador.
- Banco transferido para o pátio aberto, encosto ao norte e faixa frontal de 48 px livre ao sul.
- Auditoria automática no build e na revisão/exportação de projetos com `layout.audit.enforce`. Novos projetos já usam essa opção e curvas de 24 px. Durante a edição, rascunhos inválidos permanecem visíveis.
- Estado final: 114 objetos Tiled, 10 decorações, 107 sprites e 764 pontos de caminhada. As seis ações e os acessos permanecem conectados.
- `npm test`: 240 testes aprovados, inclusive banco de dados e WebSocket locais. Build, Pages, validação ESM e `npm run audit:world` aprovados.
- Conferência no navegador: visão geral sem grade e caminhada até o portão no Ateliê usando o mesmo renderizador e navegação do jogo. Evidência: `quintal-estrutura-v2.jpg`.
- Bancada revisada: `http://127.0.0.1:5210/?project=quintal&revision=estrutura-v2`. A chave de gravação é diferente da bancada anterior; nenhuma edição salva foi substituída.

Regras: `tools/atelie/AUDIT-RULES.md`. Testes de regressão: `world-structure.test.mjs`. A verificação automática não substitui a inspeção visual de sombras, texturas, emendas e orientação.

Mudanças locais, sem commit ou deploy nesta revisão.
