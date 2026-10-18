# Praça do PipaKlub

> Registro da primeira versão costeira. A direção atual recupera o Quintal do Clube e acrescenta exploração no Morro do Sol; veja `WORLD-ART-DIRECTION.md` e `WORLD-EXPLORATION.md`.

A tela inicial de membros usa uma praça costeira como centro de navegação, conforme a referência fornecida. O cenário, os personagens e a interface são camadas independentes. Visitantes continuam com o acesso ao treino e ao login existentes.

## Conteúdo e destinos

- Perfil: apelido, nível e XP do **pipeiro** vindos da conta. A progressão individual do Pipamon continua separada.
- Moedas: saldo confirmado das Trilhas, atualizado pelo mesmo fluxo das outras telas. Diamantes não são exibidos, pois essa economia ainda não existe.
- Mochila: consulta das rabiolas `ready` e `damaged`, com carregamento, vazio, erro e nova tentativa. A resposta é descartada se a conta mudar ou o painel for substituído.
- Pipamons: coleção existente; mapa: bairros existentes; missões: primeiro voo e progresso real das Trilhas; configurações: opções existentes.
- Prédio do clube: modos de jogo; ateliê: invocação; banca: loja de linhas; professor: primeiro voo.
- A missão e o cartão de destino usam o próximo bairro desbloqueado. Não há concessão de recompensas ao abrir os painéis.

## Cenário e movimento

Kael usa oito quadros (quatro direções, duas poses). Clicar ou tocar no caminho move o personagem; o parceiro equipado acompanha o passeio. Os dois corredores pavimentados limitam o movimento. O passeio é local e decorativo, sem sincronização de avatares entre jogadores. Não muda a simulação das batalhas.

O botão de pausa, movimento reduzido e a abertura de outros menus interrompem a animação. No movimento reduzido, cliques reposicionam imediatamente o personagem. O brilho já obtido pelo parceiro é exibido sem criar um novo sistema de partículas.

## Arte

`assets/hub/praca-v1/` contém cenário, spritesheet, retrato e seis ícones. `manifest.json` descreve quadros e arquivos públicos; `prompts.json` registra os prompts. `sources/` guarda os originais. `scripts/build-plaza-assets.mjs` faz apenas recortes e empacotamento; requer `sharp`, opcionalmente via `PIPA_KIT_NODE_MODULES`.

Os arquivos públicos têm hash no endereço e entram no allowlist do servidor e no build de Pages. Fontes e prompts não são expostos pelas rotas do jogo. A interface usa bordas de tamanho fixo em CSS: nenhuma moldura ilustrada é esticada para caber nos painéis.

## Verificação

`plaza.test.mjs` verifica XP, objetivos, limites dos caminhos e distribuição dos arquivos. `art.test.mjs` verifica a interface com dados da conta e o descarte de respostas da mochila após troca de usuário. A prévia isolada `/menu-audit`, opção “Quintal”, permite conferir desktop e celular sem acessar uma conta real.
