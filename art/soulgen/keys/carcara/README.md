# Carcará · pose-chave Soulgen

Brief entregue em 2026-10-21. Único brief pendente encontrado na branch `origin/claude/soulgen-codex`, commit `41be85d`. Os arquivos do pipeline e o exemplo foram obtidos dessa branch sem modificações; o exemplo procedural não foi usado como arte final.

## Conteúdo

- Nove camadas PNG 96×96: corpo, duas asas, rabiola e cinco expressões; normal vazia conforme contrato.
- `key.json`: 15 cores, pivôs nos ombros/laço, âncoras e variante noturna por slots.
- `pose.png` e `pose-preview.png`: composição de repouso e ampliação nearest-neighbor.
- `source/layers-generated.png`: original RGBA da arte criada com `image_gen`.
- `source/prompts.json`: prompts inicial/correção e referência de identidade.
- `prepare.py`: recorte das partes geradas, escala nearest-neighbor, alpha binário e mapeamento da paleta solicitada. Não desenha a criatura proceduralmente.
- `preview.html`: prévia independente com PNGs e dados embutidos, animação por tempos do atlas, fundo claro/escuro. Repete os clips de golpe/dano apenas para revisão; o atlas mantém `loop: false`.
- `validation.json` e `review-dark.png`: relatório técnico e evidência de revisão.

## Produção e revisão

Arte em camadas gerada a partir de `assets/creatures/basicos-v2/carcara.png`, com correção dirigida do capuz em V. A fonte de geração não tem registro exato dos slots; os recortes e o posicionamento explícitos em `prepare.py` são o contrato final, não a grade aparente da fonte.

Pose final: bounds (21,24)–(77,74), altura 50 px, classe média. Pivôs são registrados por parte; o corpo, os olhos, as asas e a rabiola permanecem no mesmo sistema de 96×96. As expressões usam só a região dos olhos e seu papel de cobertura, preservando bico, remendos e silhueta.

Executados sem alterar `tools/soulgen/`:

```text
python tools/soulgen/keyanim.py art/soulgen/keys/carcara art/soulgen/out
python tools/soulgen/keyanim.py art/soulgen/keys/carcara art/soulgen/out noturno
python tools/soulgen/lint.py art/soulgen/out/carcara.json art/soulgen/out/carcara-noturno.json
```

Resultado: ambas com 15 cores, zero erros, zero avisos, 16 quadros cada; contorno e transparência preservados na variante. Inspeção visual da pose, das cinco sequências e das duas paletas na prévia local. As asas giram pelos ombros e as fitas seguem o laço, usando o gerador existente. GIFs/atlases exportados em `art/soulgen/out/`, pasta ignorada pelo Git conforme o pipeline; podem ser regenerados a partir das camadas.

Ainda não integrado ao catálogo/renderizador do jogo, publicado, commitado ou enviado em PR. Aprovação estética final cabe à revisão do projeto. Para abrir a galeria local: `node art/soulgen/keys/carcara/serve.mjs`, porta 5235; ou abra `preview.html` diretamente.
