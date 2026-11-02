# PIP-133 · Revisão 2 — sinais com funções distintas

O dono rejeitou o uso repetido de cartões amarelos para boss e enroscada. Esta revisão substitui essas peças no jogo; as capturas da revisão anterior ficam preservadas em pip-133/.

## Direção

| Função | Forma, material e informação |
| --- | --- |
| Entrada do boss | Faixa vermelha rasgada, contrafaixa preta, reforços de papel com sinais de perigo nas pontas e varetas sob tensão. O retrato do Lacertubo rompe a borda. Chamada e nome são nativos, em creme; botão pular e bloqueio de combate preservados. |
| Boss durante o combate | Vela de pipa azul-escura, bordas e armação próprias, nós vermelhos, retrato na ponta. Linha vermelha espessa e Armação em células claras; fase, nome, nível e tempo em colunas separadas das pontas. |
| Campeã | Cabeçalho verde-água com contagem de rodadas sobre a armação escura; conserva o VS da campeã. Não confunde “fase do boss” com “rodada de campeonato”. |
| Enroscada | Flâmula dobrada verde-água, duas linhas cruzadas e amarradas à esquerda, pontas de rabiola à direita. Aviso de ação compacto e rótulo próprio; não usa chamada de perigo nem cartão amarelo. |

Amarelo continua nos controles selecionados e no relógio: sua função é foco/tempo, não servir de fundo padrão para todo evento. Os estados válidos/inválidos da enroscada continuam vindos do contato real, sem novas regras.

## Arte e construção

Três peças ilustradas originais em `godot/assets/ui/mural-v1/events-v1/`, fonte, prompts e manifesto em `art/ui/soulmonsters-v2/pip-133-v2/`. Geração nativa imagegen, referência autoral B apenas para direção artística. Fundo externo com alpha zero; RGB oculto no PNG não deve ser interpretado como fundo opaco. Recorte e normalização das linhas foram mecânicos, sem redesenho por script.

`event_art.gd` conserva as pontas no 9-slice e reserva área interna específica para cada silhueta. O recorte não usa o mesmo padding de um retângulo: topo/rodapé excluem rasgos, reforços e varetas; esquerda da enroscada exclui o nó inteiro. A conferência visual aumentou as margens após a primeira captura mostrar conteúdo perto das pontas.

Nenhum texto variável é parte do raster. A HUD de boss limita sua largura em janelas grandes. As barras e a tipografia continuam observando o modelo; os retratos vêm dos atlas aprovados. Não muda modelo, dano, XP, save, intro, pausa ou recompensas.

## Evidências

- **795 verificações, zero falhas** na suíte de batalha Mural, incluindo diferenciação cromática das três peças, margens de controles, VS, pular, pausa e leitura pura da enroscada.
- **67 verificações, zero falhas** na suíte existente de apresentação do boss.
- **9.996 verificações nativas, zero falhas** de área segura/colisões em quatro resoluções, texto 100/150%. Agora a auditoria inclui também as letras da faixa de entrada do boss.
- **40 capturas novas** em 1280×720, 1920×1080, 1024×768 e 1280×800: duelo, boss, campeã, enroscada e entrada de boss. Galeria local em index.html.
- Método e hashes em integridade.json e padding-audit*.json. Eventos são simulados nos testes; não houve teste com controle físico nem nova sessão completa de gameplay.
- A auditoria de retângulos não detecta sozinha a pintura sobre o texto: as capturas foram inspecionadas para refinar o espaço entre tinta, nós, varetas e letras. Nenhuma certificação de acessibilidade ou exportação é alegada.
- Persistem avisos ambientais de permissão de logs e shader cache. Sem push/merge ou mudança de ticket no Linear.

Esta revisão atende à distinção funcional solicitada; não representa aprovação artística do dono antes de ele ver as novas peças.

