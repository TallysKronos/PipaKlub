# Nozinho · rig artesanal em três quartos

Primeira conversão da fila de 25/10/2026. Nozinho mantém o corpo de nós de linha, rosto turquesa, laços superiores, punhos amarrados e pontas desfiadas. A câmera é três quartos para a direita, com lado distante menor. Não foi transformado em ave, coelho ou mascote com pipa decorativa.

## Abrir

`npm run studio:sprites` → http://127.0.0.1:5240/?preset=nozinho.

A biblioteca oferece **Abrir Nozinho · três quartos**. O endereço de preset usa recuperação própria, sem carregar o cache de outro personagem. Também é possível arrastar `color-rig-v2/nozinho.portable.soulgen.json` para o Studio; esse projeto incorpora os oito PNGs e pode ser aberto em outro computador.

`color-rig-v2/preview.html` é uma prévia independente com as mesmas peças e sampler: cinco ações, pausa, reinício, busca temporal, velocidade ¼×/½×/1×, fundo claro/escuro e miniatura de 128 px. Abra o arquivo diretamente no navegador. O servidor do Studio não serve esse HTML de dentro da biblioteca, preservando a restrição de arquivos existente.

## Produção e revisão

ImageGen gerou `concept-draft.png` usando Nozinho antigo como identidade e Carcará/Rabbito artesanal como estilo. A pose respeitou três quartos, mas os olhos do primeiro conceito ficaram grandes/claros. A folha `source.png` corrige para olhos escuros sem grandes áreas brancas e separa corpo, dois braços, duas pernas e três variantes de expressão. O rascunho não é a versão de rosto final. Fontes originais e prompts completos foram preservados em `color-rig-v2/prompts.json`.

`prepare.py` mede os oito recortes, isola o componente principal preservando antialiasing e registra as expressões pela área turquesa. A composição só altera a janela facial; alpha e pixels externos são verificados contra o corpo canônico. Não redesenha olhos ou anatomia por código. O PNG da folha não é sobrescrito.

`build.mjs` monta cinco peças em 168×176 unidades, com pivôs medidos nas raízes dos membros. Os dois braços entram sob o nó central para esconder suas terminações. As pernas e o braço distante também usam profundidade própria. Todos os membros são filhos do corpo, com atrasos pequenos e rotações em torno dos pontos de ligação. O nó não é uma cabeça flutuando sobre um torso separado.

| Ação | Duração | Ciclo | Expressão |
| --- | --- | --- | --- |
| Repouso | 2,4 s | Sim | Neutra |
| Flutuação | 1,2 s | Sim | Neutra |
| Movimento de treino | 1,6 s | Não; impacto 0,62 s | Foco |
| Susto/dano | 1,1 s | Não | Olhos apertados |
| Alegria | 2,6 s | Não | Olhos felizes |

## Evidência

- `preview.png`: montagem real renderizada pelo sampler do Soulgen.
- `review.png`: cinco poses de ações em fundos claro e escuro.
- `study-atlas.png` + `export.json`: 113 quadros a 12 fps, células de 256 px, zero pixels tocando bordas das células na exportação.
- `registration.json`: recortes reais, máscara facial e invariantes de alpha/exterior.
- `validation.json`: estrutura, encaixes e exportação. Os testes amostram 121 instantes por ação, inclusive ciclos, recuperação e ligações.

Reproduzir: Python/Pillow em `prepare.py`; depois `node art/soulgen/keys/nozinho/build.mjs`. O segundo comando usa `@napi-rs/canvas` somente para exportar arquivos de revisão. Uma instalação externa pode ser indicada por `SOULGEN_CANVAS_MODULE`, como nos demais exportadores. O Studio não depende desse módulo para tocar o rig no navegador.

Teste: `node --test tools/soulgen-studio/nozinho.test.mjs tools/soulgen-studio/server.test.mjs tools/soulgen-studio/editor.test.mjs`.

## Estado e limites

Gerado, montado e configurado no Studio para revisão do autor. Foram inspecionados os PNGs e as poses renderizadas, e executados os testes técnicos e de entrega HTTP. Não houve playtest visual interativo no navegador nesta etapa. As cinco ações podem ser revistas em movimento no Studio ou na prévia independente.

**O atlas antigo de Nozinho no jogo permanece intacto.** Não foram alterados catálogo, inventário, banco, habilidades, treino, abertura ou integração Godot. A exportação atual é um estudo em `art/`; sua adoção no jogo é uma etapa posterior. A fila foi atualizada para marcar Nozinho como rig existente ainda sem integração.
