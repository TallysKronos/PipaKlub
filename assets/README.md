# PipaKlub — pacote de personagens e criaturas v1

Arte original em PNG com canal alpha, criada com a ferramenta integrada OpenAI image_gen. Direção: intermediário entre ilustração 2D de aventura e pixel art de alta resolução; contornos escuros, sombras em blocos, cores legíveis. Os PNGs originais foram preservados, sem remoção de fundo por código.

## Conteúdo

- `characters/sr-assis/poses.png`: 8 poses, grade 4 × 2, 1536 × 1024. Em pé, boas-vindas, explicando, apontando, com linha, pensativo, incentivo e celebração.
- `characters/sr-assis/expressions.png`: 8 cabeças para retratos de diálogo, grade 4 × 2, 1536 × 1024. Neutro, falando, rindo, pensativo, surpreso, preocupado, determinado e piscando.
- `creatures/nozinho/sprites.png`: 16 quadros, grade 4 × 4, 1254 × 1254. Flutuação, saudação, habilidade, dano/recuperação e felicidade.
- `creatures/pipas-almaticas/idle.png`: 16 quadros, grade 4 × 4, 1254 × 1254. Cada linha traz quatro quadros de uma criatura: Carcará, Mata Verde, Azulão e Raio de Sol.
- `atlas.json`: coordenadas inteiras efetivas de todos os quadros, tamanho real das texturas, limites visíveis e sequências de animação.
- `onboarding/sr-assis.json`: oito etapas de introdução com fala, pose, expressão e animação do companheiro.
- `preview.html`: prévia interativa local; abra após extrair o pacote, mantendo as subpastas. Funciona sem servidor, conta ou instalação.
- `atlas-data.js` e `onboarding-data.js`: cópias dos dados em scripts clássicos para a prévia funcionar também por arquivo local, sem fetch.
- `PROMPTS.md`: direção e prompts usados na geração e nos ajustes.

## Identidade

**Sr. Assis:** homem de 45 anos, sem barba nem bigode; cabelo preto com mechas brancas nas têmporas; óculos de aviação na testa; jaleco branco aberto, crachá preso ao peito, camisa polo azul, calça marrom e sapatos marrons. Mentor acolhedor e pesquisador das criaturas almáticas.

**Nozinho:** companheiro almático formado por um nó de corda dourado/creme, com rosto espiritual turquesa, olhos âmbar, pequenas alças e pontas de linha que lembram a rabiola de uma pipa. Personalidade curiosa e carinhosa. Sua animação de habilidade representa um puxão das pontas do nó; a arte não altera as regras atuais do jogo.

**Carcará:** pipa almática laranja com formas de falcão e penas de papel; tipo Precisa.
**Mata Verde:** criatura de folha em forma de arraia/pipa, com nervuras e cauda vegetal; tipo Ágil.
**Azulão:** almática de escudo e nuvens, azul e creme; tipo Guardiã.
**Raio de Sol:** almática de lanterna e fitas de papel douradas; tipo Técnica.

Os personagens têm identidade própria. A referência a aventuras de colecionar criaturas orientou o gênero e o apelo visual, sem reproduzir personagens existentes.

## Usar o atlas

O JSON contém `atlases[nome].frames[id].frame = {x,y,w,h}`. Carregue a imagem indicada em `meta.image`, relativa à pasta deste arquivo. Selecione uma sequência em `animations` e avance a 5–6 quadros/s.

```js
const atlas = manifest.atlases.nozinho;
const seq = atlas.animations.idle;
const f = atlas.frames[seq[frameIndex % seq.length]].frame;
ctx.imageSmoothingEnabled = false;
ctx.drawImage(image, f.x, f.y, f.w, f.h, x, y, size, size);
```

As texturas das criaturas medem 1254 px, portanto NÃO divida assumindo células inteiras de 384 px. O atlas usa limites arredondados, com células alternadas de 313/314 px, para preservar os arquivos gerados sem reamostragem.

As expressões são retratos independentes. Use `contentBounds` para centralizar a cabeça e manter um enquadramento uniforme, como em `preview.html`. Não são máscaras que se encaixam automaticamente sobre todas as poses de corpo: isso exigiria ajustar o pivô e a escala por pose. O conjunto de poses é destinado à introdução e aos diálogos, sem ciclos de caminhada em oito direções.

A prévia respeita a preferência de movimento reduzido e permite pausar animações. As variações desenhadas são quadros-chave; confirme o ritmo visual no tamanho final do jogo antes de definir a velocidade definitiva.

Integração atual: o atlas reúne os sprites, personagens, cenários, efeitos e ícones registrados. O servidor serve os PNGs permitidos pelo atlas e catálogos; os builds copiam as mesmas imagens com hashes. Os quatro básicos possuem cinco estados de animação. Mikka lidera o Morro, Lohan a Praia e Kleie os Campanários; Kael continua fora do jogo. O Ascendente usa fundo e efeitos próprios. A introdução automática é restrita a contas autenticadas. Consulte assets/designs.json e assets/packs/auditoria-v1/README.md.
