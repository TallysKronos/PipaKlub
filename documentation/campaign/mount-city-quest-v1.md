# Um elo para a estrada — primeira montaria

## Git integrado

Base local: `codex/integracao-bosque-kronasta`.
Foi buscada e integrada `origin/codex/encosta-mobilidade` em `1f4b9fb8`,
que inclui `codex/integracao-cenarios-atualizados` (`68680247`), os interiores
modernos da casa do Kael, ateliê e loja TCG, mais o piloto da Encosta.

Checkpoint das edições locais: `27ea8b0d`. Merge: `c0578d88`.
Foram conciliados os filtros de exportação, o preview dos slots e a lista de
destinos de save para manter **loja e todas as regiões existentes**. Conflitos
de UID foram resolvidos mantendo os identificadores locais estáveis.
Nada foi enviado ao remoto nesta tarefa.

## Missão jogável

Disponível depois de concluir a montagem do primeiro parceiro com o professor.

1. Conversar com **Zeca na pracinha** da Vila do Primeiro Vento. Ele cuida de
   uma montaria de papel cuja guia tem um fecho solto. Aceitar buscar a peça;
   recusar conserva a missão disponível e não concede nada.
2. Conversar com **Lia na rua alta**, ao lado da Linha & Papel. Ela entrega
   gratuitamente o **Fecho da guia**. Não exige combate, compra ou grind.
3. Voltar a **Zeca** e entregar o fecho. A peça é consumida e Kael recebe o
   **Apito de Elo**, apresentado pelo banner de aquisição existente.

O diário de missões e o objetivo na cidade acompanham a etapa. O mapa local
marca o interlocutor correspondente. Não foi criado NPC duplicado. O fluxo
usa os NPCs que já habitam a cidade; não troca seus sprites.

## Uso

- Antes de receber o apito, a campanha bloqueia a ação e oculta o botão de
  montaria. A prévia isolada continua livre para auditoria técnica.
- Depois: **B**, direcional para cima do controle ou botão de montaria.
- Mochila → **Apito de Elo** → **Chamar montaria**. A ação espera a transição
  para a rua terminar antes de montar, evitando congelar o personagem.
- A corrida usa Shift ou a alternância de corrida existente. O parceiro
  continua usando o sistema de acompanhamento e orientação do jogo.
- O apito não é consumido. O desbloqueio vem da presença desse item no save.
- Interiores do professor e da loja não habilitam o uso pela mochila.

## Animação

16 ciclos completos (Kael + montaria), oito frames cada: caminhada e corrida
nas oito direções, com pares laterais espelhados por célula. Runtime em
`godot/assets/mounts/doberman-animated-v1/`: células 256 × 256, folhas
1024 × 512 e pivô [128, 240]. Fontes de edição e prompts são preservados em
`art/concepts/montaria-doberman/animation-v1/corrected-pack-v1/`.

O empacotamento apenas redimensiona e registra os sprites corrigidos. A escala
por direção aproxima a altura da composição estática editada. Parado, mantém
os PNGs e os encaixes retocados pelo usuário no Soulgen. Não ativa o rig de
corpo separado que foi rejeitado. A colisão de deslocamento permanece a do
controlador existente; este trabalho não criou um corpo físico maior para
simular a largura visual inteira do animal em corredores.

## Persistência

`mount_quest.gd` valida treino, cena da cidade, proximidade do NPC e sequência
de etapas. Cada operação grava item/flag e recibo no mesmo snapshot, através
de `session.commit_operation`. Repetir a entrega não duplica o apito; falha de
salvamento não publica o estado em memória. Flags são booleanas e itens usam
o inventário existente, sem migração destrutiva ou concessão automática em
saves antigos. A missão não concede XP nem moedas e não altera o balanceamento.

## Validação

Todos sem falhas:

- Missão, proximidade, etapas, recarga, duplicação e reprodução: **25 checks**.
- Fluxo nativo por `interact()` dos NPCs, recusa, recompensa, teclado, HUD,
  botão real da mochila e retomada: **19 checks**, save isolado.
- Montaria, deslocamento, câmera e parceiro: **684 checks**.
- Campanha: **206**; lobby: **66**.
- Casa moderna: **79**; professor moderno: **37**; loja moderna: **47**.
- Retomada nas regiões de mina, gelo e recifes: **99**.
- Mobilidade da Encosta: **103**.

Capturas nativas 1280 × 720 em `documentation/qa/mount-city-quest-v1/`.
Os testes de interação usam posicionamento controlado para alcançar rapidamente
as etapas; não representam uma sessão humana longa percorrendo toda a cidade.
Nenhum save real foi modificado. Não foi reexportado o executável nesta tarefa.

## Arte do item

Ícone `apito-de-elo.png`: geração imagegen original com alpha, reduzida para
128 × 128. Prompt: um único apito marfim/preto, janela de som visível,
aleta laranja de papel dobrado semelhante a orelha de pipa, alça curta de corda
dourada, traço 2D mangá, cores cel, silhueta legível, sem texto ou cenário.
Fonte integral e prompt preservados junto ao registro artístico do item.
