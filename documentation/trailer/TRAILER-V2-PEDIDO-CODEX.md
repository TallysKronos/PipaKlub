# Trailer v2 · pedido ao Codex

Contexto: trailer de 2:20 em linguagem de mangá e comics, roteiro em
`documentation/trailer/TRAILER-V2-ROTEIRO.md`. A gravação é feita no Godot com
`godot/tools/trailer_capture.gd` e a montagem com `tools/trailer/montar_trailer.py`. Tudo o que
está abaixo precisa estar no repositório (branch própria, avisando quando pronto) antes da gravação.

Prioridade: **A** = sem isso o bloco não existe; **B** = melhora muito; **C** = acabamento.

## 1. Juntar o que já está pronto (A)

- `codex/soulflight-evolucao-arte` (ritual de evolução animado) e `codex/kits-tiles-v1` (Morro,
  Cavernas e Planícies em 2D mangá) ainda não estão em `claude/unificacao`. Confirme se estão
  prontos para entrar; eu faço o merge e resolvo os conflitos.

## 2. Folhas de overworld v2 dos companheiros da caminhada (A)

A caminhada recorrente troca o companheiro em 8 biomas. Já estão em v2: Farpim, Gambalhote bebê,
Papisco e Alvacordo. Faltam, nesta ordem: **Vertim, Trincaguarda, Urso-polar jovem, Carcará,
Mata Verde e Rabbito**.

Entregue a geração original de cada uma (não reduzida), com as duas vistas lado a lado em fundo
transparente: frente 3/4 para sudoeste à esquerda e costas 3/4 para noroeste à direita, mesma escala,
pixel art com blocos marcados e contorno escuro de 1 bloco. Caminho:
`art/creatures/<família>/<forma>/overworld-diagonal-v1/geracao.png` + `normalizacao.json` com os
recortes das duas vistas. Eu converto com `tools/sprites/converter-overworld.mjs`.

## 3. O lendário rugindo (A)

Decisão do dono em 13/11/2026: o Eremor aparece somente em silhueta e com rugido, sem nome
nem revelação da aparência no trailer. A versão normal abaixo é fonte de produção, não plano público.

- **Animação de rugido** do Eremor para a arena: 8 quadros (inspira, abre a boca, rugido em 3
  quadros, recua), mesma escala e ancoragem da arte de combate atual (`combat-eremor.png`).
  Entregue como `godot/assets/campaign/eremor-rugido-v1.png` + JSON de quadros no padrão das
  animações de `content.json` (chave `roar`).
- **Versão silhueta** dos mesmos 8 quadros: preto com borda de luz fria (para o trailer).
- **Onda do rugido**: efeito de 12 quadros (anel de choque + poeira), transparente, 512×512.
  O PixelFX (MIT) pode servir de base.
- **Som do rugido**: 2 a 3 s, grave, com cauda de eco de caverna, em
  `godot/assets/audio/sfx-v1/creature/eremor_rugido_01.wav`.

## 4. Especial do Rabbito (B)

- **Impact frame** do especial: 1 ilustração 1920×1080 em preto e branco com retícula, Rabbito no
  centro do golpe, linhas de velocidade radiais. Em `art/trailer-v2/impact-especial-rabbito.png`.
- Se possível, 6 quadros de efeito do golpe (rastro de vento) para sobrepor na arena.

## 5. Ilustrações de abertura e fecho (B)

Estilo dos retratos mangá atuais (`portrait-*-manga-v1.png`), 1920×1080, em `art/trailer-v2/`:

- `abertura-carretel.png`: close das mãos do Kael amarrando a rabiola no carretel, a linha esticada
  saindo do quadro.
- `kronasta-ceu.png`: o céu de Kronasta com muitas pipas, panorâmico (pode usar o atlas mangá v3
  como referência de lugares).
- `fecho-estadio.png`: Kael e Rabbito de costas, olhando o Estádio de Kronasta ao entardecer.

## 6. Retratos que faltam (B)

Para os blocos de campeões e de personagens, no padrão `godot/assets/campaign/portrait-<nome>-manga-v1.png`:
**Mikka, Dona Neve, Ícaro, Nina** (só existe a versão antiga), **Retalho** (a criatura) e
**Tufanocorte** (a criatura). O Rato fica como está e vai em silhueta.

## 7. Letreiros e onomatopeias (C)

PNG transparente, letras desenhadas no estilo mangá (traço grosso, contorno branco por fora),
em `art/trailer-v2/onomatopeias/`: **TSK** (nó), **ZAAK** (corte), **FWUSH** (esquiva),
**KRAK** (crítico), **VUUUM** (montaria), **SPLASH** (mergulho), **GRRRAAAOOO** (rugido, enorme,
em 3 pedaços para rachar a tela). Também 2 texturas de linhas de velocidade (radial e horizontal)
em 1920×1080.

## 8. Trilha de 2:20 (B)

Se for possível gerar ou compor: uma faixa de 140 s seguindo a tabela de marcos do roteiro (entrada
da batida em 0:16, cortes a cada 3,5 s entre 0:22 e 0:50, seção intensa em 1:12, respiro em 1:34,
silêncio de 1 s em 2:02 e acorde final em 2:12). Entregue em
`godot/assets/audio/music/trailer-v2/trailer-v2.ogg` com um `marcos.json` dos tempos. Sem isso,
eu faço uma edição de 2:20 de `vento-aventura.ogg`.

## Como me avisar

Um commit por item, com título "Trailer v2: <item>", e uma linha no fim deste arquivo dizendo o
que entrou. Assim que os itens **A** estiverem no repositório, eu gravo os planos e monto a
primeira versão; os itens **B** e **C** entram na segunda passada.

## Entrega do Codex · 13/11/2026

Itens 1–8 preparados na branch `codex/trailer-v2`, com um commit por item e fechamento de QA. Guia: [ENTREGA-CODEX.md](ENTREGA-CODEX.md); prévia: `art/trailer-v2/index.html`; manifesto: [PACOTE-V2.json](PACOTE-V2.json). As duas branches-fonte continuam para o merge pelo Claude, conforme combinado. Nenhum vídeo foi gravado. Lendário público somente em silhueta e rugido, sem nome.
