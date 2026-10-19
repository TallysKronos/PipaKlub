# Um fio de sorte — abertura de PipaKlub

## Revisão — encenação de RPG clássico (19/10/2026)

- `mother-overworld-v2.png`: folha 1536×1024 RGBA, grade 4×2. Frente,
  esquerda, direita e costas na primeira linha; passos correspondentes na
  segunda. Identidade de `mother.png`, proporções e acabamento de Kael.
  Imagem produzida pela ferramenta integrada image_gen; prompt e referências
  registrados em `mother-overworld-v2-prompts.json`. Original preservado.
- Recortes por célula, bounds de alpha e apoio medidos pelo script de assets.
  A arte foi inspecionada sobre papel claro e no cenário; nenhuma remoção de
  fundo por cor ou repintura por script foi usada.
- Mãe, Kael e Rabbito usam os caminhos medidos do cômodo. O banco da mesa
  bloqueia passagem. A amostragem fina evita a rota presa na quina da porta.
- A entrega é subentendida: item centralizado sobre quarto escurecido,
  confirmação e retorno ao controle. A rabiola não voa entre as mãos.
- O brilho nasce sobre o projeto na mesa. Uma transição clara permite a
  substituição pelo parceiro no chão; aproximação e direção comunicam vínculo.
- Depois do nome, o jogador caminha à escada com Rabbito seguindo. Não há
  descrição de carinho sem pose correspondente.

Estado: integrado localmente; revisão artística final pelo responsável.

## Atualização — quarto jogável (19/10/2026)

Nos checkpoints 3 e 7, Kael agora caminha pelo quarto com WASD/setas, clique
no chão ou analógico do controle. E/A ou o botão contextual examinam o objeto
próximo. Os atalhos TV/Desenhos/Mesa conduzem o personagem fisicamente ao local.
Paredes, cama e mobília ficam fora do piso autorizado; o clique considera as
faixas vazias ao redor da imagem e não teletransporta o personagem.

A bancada usa o novo `rabbito-project-clean-v2.png`, PNG RGBA 1536×1024,
produzido com a ferramenta image_gen integrada. `project-v2-prompts.json`
preserva geração e refinamento. A primeira variante `rabbito-project-v2.png`
fica como fonte de exploração e não é publicada pelo manifesto.
Os recortes da pipa e da vareta são usados diretamente no canvas, sem pintar
ou remover alfa. O encaixe dura 950 ms; movimento reduzido apresenta a vareta
colocada sem deslocamento. O avanço só é salvo após a confirmação da montagem.
Falha de conexão permite tentar novamente, e cancelar antes de salvar não
avança o checkpoint. Depois, a mesma pipa aparece montada sobre a mesa.

A transmissão ocupa a tela física da TV: aproximação inicial e recuo ao quarto.
Com movimento reduzido, os planos mudam por corte e o lance fica estático.
Não há vencedor definido. As duas pipas continuam ilustrativas, sem estabelecer
os times definitivos de Jamile e Gollia. Ao receber o presente, Kael leva a
rabiola até a bancada antes da ação contextual de colocá-la.

Não foi necessária nova migração: os checkpoints de 017 e as proteções da
entrega única permanecem. A etapa do nascimento/primeiro contato, exploração
do andar de baixo e revisão das concessões de cadastro seguem no plano
ABERTURA-PLANO-DE-MELHORIAS.md; não são declaradas concluídas nesta atualização.

Verificação: suíte completa com 260 testes aprovada antes dos últimos ajustes
de apresentação; verificações direcionadas finais cobrem movimento, recorte,
montagem, cancelamento, falha de conexão e retomada. Auditoria no navegador
confirmou teclado/clique, bloqueio na cama, chegada à mesa, montagem salva após
recarregar e retorno à mesa com a rabiola. Controle tem integração e testes de
código; não houve teste físico de gamepad nesta rodada.

## Direção e narrativa

Kael acompanha pela TV de tubo a final regional: Jamile está perdendo espaço
para Gollia. A cena não determina o resultado da partida. No aniversário de
15 anos, Kael recebe a Rabiola Antiga de sua mãe e a liga ao Rabbito que
inventou. O nascimento termina com a escolha de nome, padrão/placeholder
Rabbito. O andar de baixo conduz ao quintal e ao primeiro treino com Nozinho.

O filme é conduzido pelo jogador, sem diálogos que desaparecem por tempo.
Enter/botão de confirmação avança; Esc/Continuar depois pausa. O ponto salvo
é recuperado na conta. Movimento reduzido elimina deslocamentos e partículas.
Clube → Rever a abertura oferece uma reprise sem entregas ou alterações no
inventário. Não há dublagem nesta versão.

## Assets e configuração

Artes geradas pela ferramenta integrada image_gen, seguindo o manual do
repositório: contornos 2D, sombras em blocos, casa brasileira, câmera elevada
ortogonal e personagens independentes do fundo. `prompts.json` preserva os
cinco prompts. Referências de estilo: `assets/world/morro-plaza-v1/plaza-base-v1.png`
e `assets/hub/praca-v1/kael.png`. Os arquivos originais da ferramenta permanecem
no diretório de imagens geradas do Codex; cópias consumidas estão neste pacote.

- bedroom.png: 1536×1024 RGB; TV, cama e mesa de criação, sem atores.
- downstairs.png: 1536×1024 RGB; sala/cozinha, escada e saída ao quintal.
- mother.png: 1774×887 RGBA; duas poses com âncoras medidas pelos pixels alfa.
- rabbito-source.png: original 1774×887 RGBA preservado.
- rabbito.png: atlas empacotado 2048×1024 RGBA, oito células 512×512.
- tail.png: 1254×1254 RGBA; Rabiola Antiga.
- manifest.json: dimensões reais, células, limites de conteúdo, posições da
  encenação, pisos e ligações entre cômodos.

`scripts/build-opening-assets.mjs` faz apenas recortes e preenchimento
transparente do atlas, sem pintar ou remover fundos. Os recortes especiais
evitam a orelha da vitória que ultrapassava a linha nominal da imagem original.
O Pipamon usa a mesma escala de atlas em repouso, voo, habilidade, dano e vitória.
O retrato da Pipa Dex tem recorte próprio em `assets/portraits.json`.

`src/opening-client.js` consome a configuração de encenação. O quarto tem a
exploração dirigida descrita acima, com navegação própria em `opening-room.js`.
O andar de baixo permanece uma cena; não foi implementada importação de
interiores Tiled. Não altera o novo quintal nem os mapas do Morro.
A transmissão usa as pipas já existentes como ilustração do duelo; os times
definitivos de Jamile e Gollia não foram definidos como cânone.

## Conta e migração

Aplicar `supabase/migrations/017_kael_opening.sql` depois de 016, antes de publicar
o servidor que utiliza `/account/opening`. Validada em PostgreSQL local/PGlite;
nenhuma migração foi aplicada ao Supabase real.

A migração acrescenta `player_openings`, nome individual opcional em
`player_kites` e o modelo Rabbito. O RPC `player_opening` exige autenticação,
trava o perfil e o checkpoint, rejeita saltos de cena, registra a rabiola
como recebida/ligada e entrega/equipa um único Rabbito permanente. O nome
aceita até 24 caracteres e vazio vira Rabbito. Novas chamadas de confirmação
retornam o mesmo parceiro, preservando o primeiro nome confirmado.

Rabbito usa a categoria interna `event` para aproveitar a proteção já existente
de vínculos e procedência; na interface e na Dex é **parceiro da história**.
A procedência é `story-kael-birthday-v1`. Não recebe receita de invocação nem
rabiola comum. A Rabiola Antiga é um item narrativo único registrado no
checkpoint, ligado ao parceiro; não entra no estoque consumível de rabiolas
do NPC, não pode ser negociada e não permite invocar outras espécies.

Contas existentes são marcadas como anteriores à abertura e mantêm seus
parceiros, nomes, equipamentos e jornadas. Podem rever o filme, sem ganhar
outra cópia. As concessões básicas já existentes no cadastro não são removidas
por esta migração. A abertura não concede moedas, XP ou vitórias.

Após o final, a jornada nova passa a `practice` com Rabbito; mantém-se o treino
já implementado. Troca/partida/invocação em andamento impedem a entrega.
Respostas tardias de outra conta não mudam o jogador atual. Falha de conexão
conserva a tela e permite retomar a confirmação no servidor.

## Revisão

Build Worker, build Pages e validador do artefato passaram. A suíte completa
passou em 258 testes; após a revisão de encenação, os 17 testes direcionados
de abertura/primeiro voo também passaram, incluindo todos os planos com
movimento reduzido. Acrescentado um teste posterior de encenação, totalizando
259 testes cadastrados.

Fluxo auditado no navegador: TV → mesa → aniversário → rabiola → nascimento →
nome vazio confirmado como Rabbito → andar de baixo → quintal → treino com
Nozinho usando Rabbito. Recarregamento retomou a cena salva. A auditoria visual
e técnica não substitui a aprovação artística do usuário.

Teste local: `/local/kael` é a conta de demonstração nova reservada para revisão;
`/local/davi` foi usada na auditoria. Não são contas de produção. Acesso a
contas existentes: Menu → Clube → Rever a abertura.
