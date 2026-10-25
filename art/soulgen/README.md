# Soulgen · arte em camadas e animação de Soulmonsters

## Fila de conversão

Primeira entrega da fila: [Nozinho em três quartos](keys/nozinho/README.md), com cinco peças e cinco ações, configurado no Studio em `/?preset=nozinho`. Aguardando revisão do autor antes de exportar para o jogo.

[Inventário e fila de produção](pendentes/README.md): 9 dos 36 Pipamons da Dex ainda sem rig Soulgen; vinte e sete com rig existente. Nozinho está configurado no Studio e aguarda revisão antes da integração ao jogo. Eremor possui projeto fora da Dex, e dois conceitos adicionais aguardam revisão de direção. Inclui galeria das referências atuais e fichas por espécie. Auditoria local de 25/10/2026; não equivale a aprovação visual nem altera os assets do jogo.

Nova entrega: [Guaravento](keys/guaravento/README.md), oito peças e cinco ações em `/?preset=guaravento`.

Nova entrega: [Micofolha](keys/micofolha/README.md), oito peças e cinco ações em `/?preset=micofolha`.

Nova entrega: [Capimansa](keys/capimansa/README.md), oito peças e cinco ações em `/?preset=capimansa`.

Nova entrega: [Tatutrama](keys/tatutrama/README.md), sete peças e cinco ações em `/?preset=tatutrama`.

Nova entrega: [Flautrevo](keys/flautrevo/README.md), quatro peças e cinco ações em `/?preset=flautrevo`.

Nova entrega: [Trinca-brasas](keys/trinca-brasas/README.md), nove peças e cinco ações em `/?preset=trinca-brasas`.

Nova entrega: [Alvaneve](keys/alvaneve/README.md), nove peças com proporções originais preservadas, em `/?preset=alvaneve`.

Nova entrega: [Chaspiral](keys/chaspiral/README.md), seis peças proporcionais e cinco ações em `/?preset=chaspiral`.

Nova entrega: [Hiponilo](keys/hiponilo/README.md), oito peças proporcionais e cinco ações em `/?preset=hiponilo`.

Nova entrega: [Marulume](keys/marulume/README.md), quatro peças proporcionais e cinco ações em `/?preset=marulume`.

Nova entrega: [Jarabrasa](keys/jarabrasa/README.md), quatro peças proporcionais e cinco ações em `/?preset=jarabrasa`.

Nova entrega: [Jaguarluar](keys/jaguarluar/README.md), oito peças proporcionais e cinco ações em `/?preset=jaguarluar`.

## Diretriz atual aprovada

**Atualização de 24/10/2026:** [Direção de arte baseada no Carcará](DIRECAO-ARTE-CARCARA.md). Olhos pequenos e escuros, bico quando a espécie for ave, papel facetado e remendos artesanais. O lote v1 ficou como histórico da tentativa. A [revisão v2](keys/basic-color-v2/README.md) foi regenerada nessa direção, com conceitos e rigs editáveis para revisão final.

A referência aprovada pelo usuário em 2026-10-21 é o **rig colorido com expressões registradas do Carcará**. Preserve a arte original em cores e detalhes, articule as partes por pivôs fixos e sincronize olhos/sobrancelhas com golpe, dano e vitória. Não converta automaticamente esse modelo em pixel art ou em uma variante monocromática.

- [Diretrizes completas de criação, animação e revisão](DIRETRIZES-RIG-COLORIDO.md)
- [Modelo de brief para novas criaturas](BRIEF-RIG-COLORIDO.template.json)
- [Exemplo aprovado e reprodução](keys/carcara/color-rig/README.md)
- [Prévia independente do Carcará](keys/carcara/preview.html)
- Novo lote colorido editável: [Mata verde, Azulão, Raio de sol e Rabbito v2](keys/basic-color-v2/README.md)

O exemplo é a referência do comportamento e do acabamento aprovados. Espécies novas precisam de suas próprias anatomias, cores, fontes, recortes e pivôs; não devem herdar coordenadas do Carcará por cópia.

## Pipeline anterior de pixel art

As regras abaixo descrevem um formato alternativo anterior. A grade 96×96, a paleta de até 15 cores, o alpha binário e `tools/soulgen/lint.py` só se aplicam a esse formato quando solicitado explicitamente. Não são critérios de aprovação do rig colorido. Os arquivos e ferramentas anteriores permanecem preservados.

Integração entre quem desenha (Codex ou artista) e o gerador (Claude). O artista desenha **uma pose-chave por espécie**, separada em camadas; o gerador faz todas as animações, variantes de cor e verificações, e exporta no formato do jogo.

```
briefs/<id>.md + <id>.json  →  keys/<id>/ (pose-chave em camadas)  →  tools/soulgen/keyanim.py  →  out/<id>.png/.json/-atlas.json + GIFs
                                                                       tools/soulgen/lint.py (verificador)
```

## Para o Codex

1. Abra `briefs/` e pegue um brief com `"status": "pendente"` no `.json`.
2. Entregue em `keys/<id>/` exatamente os arquivos listados no brief (camadas PNG + `key.json`).
3. Rode e corrija até passar:
   ```
   python3 tools/soulgen/keyanim.py art/soulgen/keys/<id> art/soulgen/out
   python3 tools/soulgen/lint.py art/soulgen/out/<id>.json
   ```
4. Mude o `status` do brief para `"entregue"` e abra o PR. Não altere `tools/soulgen/` nem nada fora de `art/soulgen/keys/<id>/` e do brief.

`keys/_exemplo-carcara/` mostra o formato completo. É um **placeholder gerado por código** para testar o pipeline, não arte final e não referência de qualidade.

## Formato da pose-chave (`keys/<id>/`)

| Arquivo | Conteúdo |
|---|---|
| `body.png` | Corpo (vela da pipa, varetas, rosto neutro, bico, remendos) |
| `wing-near.png` | Asa do lado do observador (desenhada por cima do corpo) |
| `wing-far.png` | Asa de trás (fica atrás do corpo) |
| `tail.png` | Rabiola completa, pendurada no nó |
| `face-<expr>.png` | Só os pixels que mudam no rosto: `normal` (pode ser vazio), `blink`, `fierce`, `hurt`, `happy` |
| `key.json` | Paleta, pivôs, âncoras, cores de efeito e variantes (ver exemplo) |

Todas as camadas: **96×96**, fundo transparente, mesma posição (empilhadas formam a criatura). A criatura cabe na célula central de 64×64 (x 16–80, y 16–80), com a asa aberta em repouso.

`key.json`:
- `palette`: até **15 cores** (`#rrggbb`), a primeira é o contorno. Nenhum pixel pode usar cor fora desta lista.
- `variants.<nome>`: lista do mesmo tamanho; a cor *i* vira a cor *i* da variante. O contorno (posição 0) não muda.
- `parts.<camada>.pivot`: pixel do ombro (asas) ou do nó (rabiola), em coordenadas da camada. `side`: para onde a asa se estende (`left`/`right`).
- `anchors`: `head` (meio da testa, onde aparecem ícones), `center`, `effect` (origem do golpe), `tail` (nó).
- `fx`: quatro cores da paleta para efeitos (`hot` claro, `mid`, `dim`, `edge` escuro).

## O que o gerador faz com a pose

- Repouso, voo, habilidade, dano e vitória (16 quadros), com durações irregulares em ticks de 1/60 s e `hitFrame` no golpe.
- Asas giradas no ombro com rotação RotSprite (vizinho mais próximo em 8×): nenhuma cor nova aparece.
- Rabiola balançando, corpo respirando e inclinando, troca de rosto, efeitos (pena, corte, brilho).
- Variantes por troca de paleta, verificadas: contorno e transparência não mudam.

## Verificador (`tools/soulgen/lint.py`)

Reprova: mais de 15 cores; alfa semitransparente; cor fora da paleta; quadros ≠ durações; habilidade sem `hitFrame`; âncora ausente; encostar na borda da célula; animação obrigatória faltando; tamanho fora da classe; variante que muda contorno ou transparência. Avisa: margem menor que 3 px, ritmo totalmente uniforme.

## Estado

O que sai em `out/` não entra no jogo automaticamente. A integração ao atlas do jogo é um passo separado, depois da aprovação visual.

Próximo passo opcional: com o Codex instalado no Linear, cada brief vira uma issue delegada ao Codex, e a revisão do gerador volta como comentário na issue.

Nova entrega: [Azulongo](keys/azulongo/README.md), cabeça chibi e cinco peças proporcionais em `/?preset=azulongo`.

[Direção das quatro bestas](DIRECAO-QUATRO-BESTAS.md): corpo de filtro dos sonhos aplicado no Azulongo e no [Auriflama](keys/auriflama/README.md).

Nova entrega: [Umbrocasco](keys/umbrocasco/README.md), casco de filtro dos sonhos e serpente articulada em `/?preset=umbrocasco`.

Nova entrega: [Nevagume](keys/nevagume/README.md), tigre branco com filtro dos sonhos, sete peças e cinco ações em `/?preset=nevagume`.

Nova entrega: [Rexal](keys/rexal/README.md), oito peças e cinco ações em `/?preset=rexal`.

Nova entrega: [Tricerafan](keys/tricerafan/README.md), oito peças e cinco ações em `/?preset=tricerafan`.

Nova entrega: [Pteralis](keys/pteralis/README.md), seis peças e cinco ações em `/?preset=pteralis`.

Nova entrega: [Stegaru](keys/stegaru/README.md), oito peças e cinco ações em `/?preset=stegaru`.
