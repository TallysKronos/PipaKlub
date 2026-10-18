# Um fio de sorte — abertura de PipaKlub

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

`src/opening-client.js` consome a configuração de encenação. Esses cômodos são
cenas da abertura; este pacote não declara implementada uma exploração livre
de interiores com colisões/Tiled. Não altera o novo quintal nem os mapas do Morro.
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
