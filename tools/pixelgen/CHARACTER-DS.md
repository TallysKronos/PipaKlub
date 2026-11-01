# Base de personagens Soulmon DS

Base reutilizável de produção, sem copiar pixels comerciais ou treinar um gerador. O usuário pediu a leitura de personagens de RPG de aventura de Nintendo DS, mantendo a identidade de Soulmonsters. O estudo de Kael v3 orienta aparência; os lotes v1/v2 rejeitados não são padrões aprovados.

## Bancada e proporções

Em **Projetos → Começar um sprite**, escolha **personagem Soulmon DS**, tipo de corpo e nome. O novo projeto tem oito direções vazias, sete camadas, ficha e pontos anatômicos. A criação participa do histórico; arquivos legados conservam seu formato. Guias de topo, queixo, ombro, quadril, joelho e pés são ligadas por **Proporções**, não alteram os pixels e não entram nas exportações. A prévia de personagens novos começa em **1×**.

| Variante | Célula | Altura inicial | Pés | Pivô |
|---|---|---|---|---|
| Padrão | 48×64 | 54 px | y=61 | 24,62 |
| Compacta | 32×48 | 42 px | y=45 | 16,46 |

Corpos: jovem ≈3,2 cabeças, adulto ≈3,5 e robusto ≈3,1 com ombros largos. São guias iniciais, não anatomia universal. A ficha permite ajustar proporções; crianças, idosos e corpos especiais precisam de direção própria. A paleta inicial tem 20 cores opacas + transparência e rampas editáveis. Cabelo, pele, roupa, acessórios e assimetrias pertencem a cada personagem, não ao preset.

## Produzir em etapas

1. Uma pose cardinal desenhada e revista nos pisos em tamanho real.
2. Um ciclo curto, com contato/passagem, joelhos legíveis, braços opostos às pernas e peso.
3. Direções restantes e só depois outras ações.

As caixas **Revisei a pose base em 1×** e **Revisei um ciclo curto** registram revisão visual manual. Não são aprovação automática. A bancada recusa marcar uma base vazia e exige base marcada + caminhada com mais de um quadro para o ciclo. `check` sinaliza expansão acima de dois movimentos sem as duas revisões. Mudanças posteriores na arte exigem nova revisão: desmarque e registre novamente. Isto não é um controle de segurança.

O perfil mede os pixels pintados em Cabeça/Cabelo: acima de 40% da altura em poses em pé gera erro. Também mede separação para o Tronco, detectando cabeça solta. Cabelo longo, chapéus e poses especiais podem gerar alertas que pedem julgamento humano. Preserve as camadas nomeadas para manter essas medições; alterá-las gera aviso. A ficha continua medindo cabeça, altura, apoio e cores a partir dos pontos anatômicos. Não manipule pontos para ocultar erros nos pixels. Identidade e qualidade de movimento continuam sendo decisões visuais.

## CLI para agentes

```sh
npm run pixel -- new nina.pixelgen.json --profile soulmon-ds-v1 --body jovem --name Nina
npm run pixel -- render nina.pixelgen.json --out tmp/nina --frame 0 --pose
npm run pixel -- render nina.pixelgen.json --out tmp/nina --frame 0 --grounds
npm run pixel -- check nina.pixelgen.json
npm run pixel -- profile nina.pixelgen.json --base-reviewed true
```

Corpos: `jovem`, `adulto`, `robusto`; `--size 32x48` cria a variante compacta. A base recém-criada reprova entrega por estar vazia. O comando `profile` não preenche desenhos e só registra revisão se já houver pixels. Depois de revisar o ciclo, usar `--cycle-reviewed true`.

## Folhas compatíveis

```sh
npm run pixel -- pack nina-idle.pixelgen.json nina-walk.pixelgen.json --out tmp/nina-pack --columns 8
```

Documentos devem ter o mesmo `sheet.nome` (identidade), perfil/corpo, célula, paleta e margem/pivô. Cada ação ganha uma folha com oito linhas fixas **S, SO, O, NO, N, NE, E, SE**, oito colunas por padrão e células vazias transparentes. `climbdown-N` pode compartilhar os quadros de `climb-N`. Nomes inválidos, duplicados e quadros sem sequência são recusados antes de escrever.

Saem PNGs por ação, `completo.png` empilhado e `completo.atlas.json`, com recortes globais/locais, fontes, pivôs, durações e ordem efetiva de reprodução. Use `sequence.frames`: reverso/ping-pong já estão materializados; não inverter novamente. O atlas do pacote difere do atlas compacto de documento único.

Sem trim, escala, recoloração ou correção silenciosa de incompatibilidades. Limite: 16 MP e altura de 16.384 px; dividir bibliotecas maiores em volumes. O montador não aprova a arte. PNG/atlas de documento único, Aseprite e exportação Godot existentes permanecem disponíveis; o atlas de pacote não tem importador automático para Godot nesta etapa.

## Evidência

`npm run studio:pixel:check` confere regressões e criação/perfil no DOM, cabeça pintada grande/solta, persistência, histórico e montagem exata de cores, recortes e sequências reversas. Canvas DOM simulado: não comprova layout visual nem movimento no jogo. Nenhum personagem novo é instalado na campanha por esta alteração.


## Esqueleto articulado (pose, não recorte giratório)

As bases jovem, adulta e robusta agora incluem 14 juntas em cada uma das oito direções. O quadril é a raiz; pescoço sustenta cabeça/ombros; braços têm cotovelo e mão; pernas têm joelho e pé. Os comprimentos são medidos no plano do sprite: cada direção pode ter encurtamento próprio por perspectiva.

Na bancada, ative **Mostrar ossos → Editar juntas por arraste** no painel Esqueleto articulado. Arrastar mãos/pés usa IK de dois segmentos; arrastar cotovelos/joelhos gira o ramo a partir da junta pai. Arrastar o quadril desloca o corpo, resolvendo novamente as pernas com apoio. Pés verdes estão presos; desmarque o respectivo apoio para movê-los. Um alvo inalcançável para mão/pé para no alcance do membro; se o quadril exigir soltar um apoio ou sair da célula, a edição é recusada. Há arredondamento à grade inteira; revise variação de até aproximadamente um pixel nas juntas.

Cada arraste permite desfazer/refazer. O esqueleto fica em `frame.pose`, o contato em `frame.support`; ambos sobrevivem à duplicação, arquivo Pixelgen e atlas JSON, inclusive no pacote de folhas. Projetos antigos com nove pontos continuam válidos; **Completar juntas** acrescenta os pontos intermediários sem substituir os já existentes. As antigas receitas raster continuam como rascunho e não recebem garantia de contato por IK; walk/run não herdam travas de pés do quadro parado.

**Copiar pose / Colar pose compatível** e **Exportar / Importar esqueleto** reutilizam a estrutura entre documentos com mesma célula, tipo de corpo e direção. Esqueletos exportados incluem a hierarquia e âncoras de cabelo, gola, cinto e acessórios das mãos. As âncoras são coordenadas de referência: não conectam nem deformam camadas automaticamente. Metadados de esqueleto não são inseridos no arquivo Aseprite; preserve o `.pixelgen.json` ou o JSON do esqueleto junto à arte.

```sh
npm run pixel -- skeleton personagem.pixelgen.json --frame 0 --complete
npm run pixel -- skeleton personagem.pixelgen.json --frame 0 --support peTras
npm run pixel -- skeleton personagem.pixelgen.json --frame 0 --export jovem-S.skeleton.json
npm run pixel -- skeleton outro.pixelgen.json --frame 0 --import jovem-S.skeleton.json
```

O painel **Revisar apoio e pixels soltos** e o CLI `check` incluem avisos de osso com comprimento zero, variação de segmento e deslizamento de pé marcado entre poses. Os avisos pedem revisão; um pé em deslocamento uniforme pode ser correto numa animação com câmera fixa no personagem.

O próximo passo artístico é desenhar uma pose e um ciclo curto sobre esse gabarito. Mover ossos modifica exclusivamente referências: não cria arte final, não gira os pixels e não produz sozinho um ciclo desenhado.
