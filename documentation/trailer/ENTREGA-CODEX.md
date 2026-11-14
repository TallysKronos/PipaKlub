# Trailer v2 — entrega ao Claude

Branch: **`codex/trailer-v2`**, baseada em `claude/unificacao` (`59ab40f1`).
O Claude grava e monta o vídeo. Esta entrega prepara os assets e valida os arquivos;
nenhum vídeo foi gravado. Prévia local: `art/trailer-v2/index.html`.

## Antes de gravar

1. Integrar esta branch à sua branch de trabalho.
2. Integrar as branches do ritual e dos kits conforme
   [TRAILER-V2-INTEGRACOES.md](TRAILER-V2-INTEGRACOES.md): pontas `fbcea502` e `98ac9b6f`.
   Os merges e conflitos continuam sob responsabilidade do Claude, como no pedido.
   Não habilitar Soulflight experimental por acidente. Os kits são assets; aplicar e
   conferir seus materiais nos planos continua sendo parte da integração dos mapas.
3. Manter a decisão do dono: **lendário somente em silhueta e com rugido, sem nome ou aparência**.
   O atlas normal é fonte interna; não alternar para ele na gravação.

Não houve merge ou push em `main`. As 40 animações locais da worktree de estudos
foram preservadas; não são substituídas nem exigidas por esta entrega de trailer.

## O que entrou

| Item | Entrega |
| --- | --- |
| 1 | Branches-fonte, SHAs, evidências e cuidados de integração documentados |
| 2 | Seis gerações originais em seus caminhos de família/forma, recortes, seis folhas v2 convertidas e editáveis |
| 3 | Rugido normal e silhueta: oito quadros, 350×313 por célula, 2,9 s, apoio (175,285); onda: doze quadros de 512×512; som separado |
| 4 | Impact frame P&B do Rabbito 1920×1080 e rastro de vento: seis quadros de 512×512 |
| 5 | Abertura das mãos, céu de Kronasta e fecho no estádio: 1920×1080 |
| 6 | Retratos mangá de Mikka, Dona Neve, Ícaro, Nina, Retalho mascarado e Tufanocorte, com transparência |
| 7 | Sete onomatopeias, rugido também dividido em três pedaços e duas texturas de velocidade 1920×1080 |
| 8 | Edição de “Vento · aventura” com 140 s, marcos e silêncio para o rugido |

Os caminhos, dimensões esperadas e hashes estão em [PACOTE-V2.json](PACOTE-V2.json).
As fontes e prompts estão em `art/trailer-v2/fontes/`, nos caminhos das famílias de
criaturas e em `art/trailer-v2/sprites/`. A proveniência evita atribuir licença de
terceiros a material gerado ou criado neste projeto.

### Lendário e efeitos

- Público: `godot/assets/campaign/eremor-rugido-silhueta-v1.png` e `.json`.
- Interno: `godot/assets/campaign/eremor-rugido-v1.png` e `.json`.
- Onda: `godot/assets/campaign/eremor-onda-rugido-v1.png` e `.json`.
- Vento do Rabbito: `godot/assets/campaign/rabbito-rastro-v1.png` e `.json`.
- Rugido: `godot/assets/audio/sfx-v1/creature/eremor_rugido_01.wav`.

Os JSONs incluem `image`, `frames`, `animations` e `durations_ms`. Respeitar os
tempos individuais; `roar` não é um ciclo infinito. Para tocar um atlas separado,
carregar a imagem indicada no próprio JSON junto dos recortes. Não aplicar seus
recortes à imagem antiga `combat-eremor.png`, que tem outra disposição de quadros.
`content.json` e a batalha normal não foram trocados para o atlas de trailer.

### Conversão dos companheiros

As seis fontes estão no padrão pedido, em
`art/creatures/<família>/<forma>/overworld-diagonal-v1/geracao.png` e `normalizacao.json`.
Quatro gerações existentes foram preservadas byte a byte; Vertim e Urso-polar jovem
foram produzidos usando seus concepts. A frente original do Carcará aponta SE:
o JSON marca `flip_x` apenas nessa vista e o conversor entregue aplica a correção.
Não espelhar novamente a folha v2 já convertida. As costas NW ficam intactas.

```
cd tools/sprites
npm ci --ignore-scripts
node converter-overworld.mjs vertim trincaguarda urso-polar-young carcara mata-verde rabbito
```

O conversor inclui inicialização WASM compatível com Windows e alturas finais para
as criaturas regionais que não possuíam uma folha v1. Mantém o contrato de células
112×112 e apoio (56,100). O validador agora aceita criaturas que estreiam diretamente
em v2, mantendo a exigência de modelo registrado e textura correta.

## Planos da caminhada

| Cena | `--partner` |
| --- | --- |
| `park-trail` | `farpim` |
| `kronasta-bosque-a` | `gambalhote-baby` |
| `planicie-d` | `papisco` |
| `caverna-c` | `vertim` |
| `vulcao-a` | `trincaguarda` |
| `serra-gelada-a` | `urso-polar-young` |
| `abismo-b` | `capivara-boia` |
| `kronasta-palafitas-b` | `alvacordo` |

No Abismo o renderer existente coloca o Kael na Boia; o ID correto da família
aquática é `capivara-boia`. O carregamento das oito combinações retornou `MOTIVO`
e `READY`. Isso não confirma enquadramento ou ausência de árvores diante da câmera.
O Claude deve escolher `--at=u,v` na inspeção visual antes da gravação final.

O comando de gravação continua sendo o do roteiro. `--storage=<pasta nova>` é uma
opção extra para ambientes restritos, mantendo o save de produção separado.
O teste abaixo **não grava vídeo**:

```
python tools/trailer/verificar_planos_v2.py --godot <executavel-do-godot>
```

## Áudio e montagem

Faixa: `godot/assets/audio/music/trailer-v2/trailer-v2.ogg`; tempos em `marcos.json`.
É uma edição da faixa existente, não uma trilha inédita com stems isolados. Entre
2:02 e 2:12 a música é silenciada; sugestão para o rugido separado: entrada em 2:03.
Antes de fechar a mixagem, ouvir os dois áudios na página de entrega e ajustar o
volume para o vídeo. Foram medidos duração, picos e ausência de clipping digital;
não há aprovação auditiva humana, LUFS ou true-peak certificados.

As partes de `GRRRAAAOOO` têm 512×1024 cada: colocar em x=0,512,1024, y=0 para
reconstituir o original 1536×1024, ou animar cada pedaço separadamente.

## Conferências executadas e limites

- Revisão independente de arte: todos os itens passaram sem bloqueios; notas e
  limitações em [REVISAO-ARTE-CODEX.md](REVISAO-ARTE-CODEX.md). Não equivale à aprovação do dono.
- 510 verificações de companheiros passaram. O teste anterior apontava duas
  exigências de folha v1 para as criaturas novas; o contrato foi corrigido e a suíte repetida.
- Oito cenas abriram em smoke test headless, sem gravação e com saves de teste isolados.
- Os três validadores de kits passaram na worktree-fonte: 23 texturas e 17 peças.
- Verificação de dimensões, alpha, hashes, recortes e tempos em
  [VALIDACAO-PACOTE-V2.json](VALIDACAO-PACOTE-V2.json). Repetir com
  `python tools/trailer/validar_pacote_v2.py`.

Ressalvas de arte registradas: onda de choque mais contida, detalhes densos na
Trincaguarda e pequeno ponto turquesa nas costas do Urso. Não foram considerados
bloqueios na revisão. Enquadramento, atuação dos planos, integração dos materiais,
mixagem final e montagem de 2:20 continuam sendo a etapa de gravação do Claude.
