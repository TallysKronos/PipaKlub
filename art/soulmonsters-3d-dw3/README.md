# Criar um Soulmonster 3D articulado

Use este guia para transformar uma prancha aprovada em uma criatura jogável no Blender e na Godot. A referência de *Digimon World 3* orienta a economia de geometria, a pintura em baixa resolução e a leitura à distância. A identidade de cada criatura vem da sua prancha de Soulmonsters. Comece pelo exemplo com anatomia mais próxima e abra o Blender e o render lado a lado.

## Escolha um exemplo

| Exemplo entregue | O que estudar | Triângulos / malhas / ossos no GLB | Clipes |
|---|---|---:|---|
| [Mormaço livre](mormaco/Mormaco-livre.png) · [Blender](mormaco/Mormaco.blend) · [GLB](mormaco/Mormaco.glb) | Quadrúpede baixo. Ombro, cotovelo e palma sustentam uma carapaça larga. A pata levanta mantendo três apoios. | 2.382 / 63 / 15 | Firmar apoio |
| [Kirin vulcânico evoluído](kirin/Kirin.png) · [Blender](kirin/Kirin.blend) · [GLB](kirin/Kirin.glb) | Quadrúpede alto. Máscara, chifre em arco, crina, vela dorsal e quatro anéis acompanham cadeias diferentes. | 3.014 / 1 / 22 | Idle, Despertar, Imponencia |
| [Rabbito criança](rabbito/Rabbito.png) · [Blender](rabbito/Rabbito.blend) · [GLB](rabbito/Rabbito.glb) | Bípede pequeno. Orelhas assimétricas, gola dobrada, roupa curta, azul na lateral da perna e no calcanhar, dois cordões. | 1.828 / 1 / 15 | Idle, Alerta |

Os três GLBs usam um material cada. Na amostra de DW3 estudada, Renamon tinha 848 triângulos e 22 ossos, Kyubimon tinha 1.779 e 45, e MegaGargomon tinha 1.678 e 27. São medidas dos arquivos de referência fornecidos. Use-as para decidir onde gastar geometria. Um osso útil pode valer mais para a expressão do que subdividir o rosto. O Mormaço anterior tinha 9.906 triângulos e 17 materiais e ainda perdia a expressão de frente.

## 1. Fixar a identidade e a escala antes da malha

1. Identifique personagem, estágio e estado narrativo. Registre a prancha usada. Mormaço livre e possuído, por exemplo, precisam de decisões de cor e expressão diferentes. Consulte a [prancha do Mormaço](mormaco/Mormaco-vistas.png), as [vistas do Kirin](kirin/referencias/prancha.png) e as [vistas do Rabbito](rabbito/Rabbito-vistas.png).
2. Marque na frente e no perfil os olhos, queixo, ombros, quadris, dobras dos membros, sola e raiz dos apêndices. Alinhe as vistas pela sola e pelos olhos. Se os desenhos discordarem, use o perfil para profundidade e a frente para largura e expressão. Confira a decisão em três quartos.
3. Anote três traços que precisam sobreviver à redução e um detalhe assimétrico. No Rabbito são orelhas com varetas, gola e rabiola dupla. O remendo pertence a uma orelha específica. Verifique também o verso e os calcanhares.
4. Defina chão, direção da frente e tamanho junto ao personagem de escala do jogo. Trabalhe na pose neutra, com câmera ortográfica. Nos geradores, as coordenadas da prancha são convertidas para o espaço do Blender. Preserve a função de conversão do exemplar ao reutilizar suas medidas. Na Godot, confirme escala e orientação ao lado do jogador antes de inserir a criatura na campanha.

## 2. Fazer o volume funcionar sem pintura

Separe primeiro caixa torácica, bacia, crânio e mandíbula. Construa cada massa com poucas seções transversais, variando largura, profundidade e inclinação. No quadrúpede, desenhe a linha ombro → cotovelo → punho → palma pelo perfil. Engrosse o músculo acima da dobra, estreite a junta e abra a base de apoio. Achate a sola no plano do chão. No bípede, deixe uma transição visível entre coxa, tornozelo e pé. Confira a folga do braço em relação à roupa.

Invista faces no que muda o contorno quando a câmera gira. No Kirin, o chifre precisa de uma seção que afina ao longo do arco. Cada anel deve envolver a cauda perpendicularmente à sua direção local. No Mormaço, sobreponha placas com uma borda inferior visível e assente os bocais dos gêiseres sobre a curva do casco. No Rabbito, dê espessura às orelhas dobradas e modele a gola separada da barra da capa. Pintar esses recortes sobre um tronco liso só funciona em um ângulo.

**Prova de volume.** Use um material cinza, esconda água e efeitos, e renderize de frente, perfil e três quartos. Recorte pela silhueta e reduza a criatura a 120 px de altura. Procure o focinho, a articulação e os apoios com o olho. Compare com a [prova do Mormaço](mormaco/Leitura-120px.png). Se a testa vira uma aba reta ou as pernas parecem tubos, corrija as seções antes de pintar.

## 3. Pintar para a câmera do jogo

Use ilhas UV próprias para rosto, flancos, ventre, patas e acessórios que têm leituras distintas. Compartilhe o atlas e espelhe apenas o que for simétrico. Nos exemplos, o Kirin usa 512 × 512; o Rabbito usa 768 × 640; o Mormaço reduz sua prancha para 768 × 512 durante a construção. Comece pela menor resolução que preserve pupila, borda e marca de espécie na câmera prevista.

- **Rosto.** Coloque olho e sobrancelha na superfície anterior que também aparece em três quartos. Preserve a direção do olhar e a sombra sob o supercílio. Reserve uma ilha própria se a projeção lateral duplicar o olho ou puxar a linha da boca pela bochecha.
- **Corpo.** Pinte a sombra sob a placa, o vinco da junta, o plano iluminado do músculo e a passagem de cor para a palma. Faça a marca acompanhar o volume de frente até o perfil. O [gerador de pintura do Rabbito](rabbito/pintar.py) tem ilhas distintas para coxa e pé.
- **Bordas.** Estenda o pigmento além das bordas das ilhas. Uma ponta de garra pode capturar o fundo ou um pedaço da garra vizinha. Gire o modelo e teste também em miniatura. Para manchas assimétricas ou costuras, confirme o lado no render de costas.
- **Material.** Use filtragem de texel por vizinho mais próximo e brilho especular baixo. Neste pacote, uma pequena contribuição emissiva preserva a pintura sob a iluminação de apresentação. Ajuste-a na arena real se as áreas claras perderem relevo. Verifique no GLB reimportado a textura embutida e a amostragem usada pelo motor.

## 4. Montar o esqueleto e distribuir pesos

Use uma raiz estável e mantenha o plano de contato dos pés coerente com a origem. Posicione cada pivô no centro anatômico da dobra. Um ponto de partida para quadrúpedes é raiz → tronco → pescoço → cabeça, com mandíbula filha da cabeça. Cada perna parte do tronco ou quadril e segue até o apoio. Para bípedes pequenos, separe braços, pernas e pés; acrescente ossos para o que comunica intenção, como as orelhas independentes do Rabbito.

Dê peso rígido às peças que mantêm a forma: garra ao osso da pata, olho ao crânio, aro ao segmento correspondente da cauda. Na pele que dobra, intercale um anel de vértices entre os ossos e distribua os pesos entre os dois lados. Para mechas e rabiolas, deixe a raiz firme e aumente a influência secundária rumo à ponta. A respiração do Kirin tem um osso próprio no peito, permitindo expandir o tórax com os quatro cascos plantados. A [implementação do Kirin](kirin/construir.py) mostra essa separação.

Teste as poses extremas enquanto os pesos ainda são fáceis de editar. Dobre uma pata, incline apenas uma orelha e abra a mandíbula. Procure unha parada durante o passo, acessório atravessando o corpo, dobra amassada e vértice sem peso. Confira que a soma dos pesos por vértice é próxima de 1. O [teste do Mormaço](mormaco/validar.py) mede o modelo reimportado e inclui unhas e falanges no cálculo de contato.

## 5. Animar intenção, apoio e retorno

Comece pela ação que distingue a criatura. Estabeleça preparação, pose principal, tempo de leitura e recuperação. Só então anime os movimentos secundários com atraso progressivo. Evite dar a todos os ossos o mesmo seno e a mesma fase.

| Movimento | Construção | Como verificar |
|---|---|---|
| Idle em ciclo | Respiração no peito, mudança discreta no olhar, atraso da crina ou cauda. No Kirin dura 5 s. | Compare primeiro e último quadros e assista à emenda por dois ciclos. Observe também a velocidade dos apêndices ao cruzar a emenda. |
| Imponência do Kirin | Abaixa, ergue chifre e pescoço, sustenta o olhar, acomoda a cauda e relaxa em 6 s. | Confira os quatro cascos, a diferença para o despertar e o retorno automático ao idle. [GIF](kirin/Imponencia.gif) |
| Alerta do Rabbito | A cabeça vira e uma orelha testa o vento antes da outra. Os cordões acompanham depois. | Na escala pequena, a primeira orelha deve ser identificável e a gola deve permitir ler a cabeça. |
| Firmar apoio do Mormaço | Uma pata dianteira sobe e volta enquanto as outras três sustentam o corpo. | Compare contato nos quadros 1, 10, 18, 29 e 40. O teste do exemplar usa tolerância de 0,0005 unidade Blender para o solo. |

Use ações com nomes estáveis e uma faixa NLA por clipe quando exportar por faixas. Garanta que cada ação comece com os canais que ela usa em estado conhecido. Teste os clipes no motor, inclusive quando interrompidos ou repetidos. Os gêiseres desta versão do Mormaço são estáticos; efeitos animados têm de ser planejados como uma entrega própria.

## 6. Reproduzir e testar este pacote

As versões usadas foram Blender 5.3 e Godot 4.7.2. Os exemplos abaixo partem **da pasta da criatura**. Substitua os comandos pelos caminhos dos executáveis locais se necessário. O GLB e o Blender editável podem ser abertos diretamente. Para reconstruir, use uma cópia de trabalho: os geradores regravam modelo, exportação e renders na pasta do script.

| Criatura | Preparar pintura em Python externo | Construir no Blender | Verificação específica |
|---|---|---|---|
| Mormaço | A prancha já acompanha o gerador | `blender -b --python-exit-code 1 -P construir.py` | `blender -b --python-exit-code 1 -P validar.py -- Mormaco.glb` |
| Kirin | `python atlas.py` (Pillow e NumPy) | `blender -b --python-exit-code 1 -P construir.py` | Após reconstruir, copie `Kirin.glb` sobre `teste-godot/kirin-animado.glb`. A cena usa essa cópia. |
| Rabbito | `python pintar.py` (Pillow) | `blender -b --python-exit-code 1 -P construir.py` | `godot --headless --script verificar.gd -- Rabbito.glb`. Espere `RABBITO_OK 15`. |

Para testar o Kirin, abra [o projeto de demonstração](kirin/teste-godot/project.godot) e execute a cena. **P** aciona imponência, **I** volta ao repouso, **Espaço** aciona despertar e as setas giram a câmera. Para verificar a troca de estados por linha de comando, rode na pasta `kirin/teste-godot`:

```sh
godot --headless --editor --import
godot --headless --fixed-fps 30 --quit-after 430 -- --poses
godot --headless --fixed-fps 30 --quit-after 400 -- --smoke
```

Verifique as mensagens `KIRIN_IDLE_LOOP_IMPONENCIA_RETORNO_OK` e `KIRIN_FULL_SEQUENCE_AND_REPLAY_OK`. O script opcional `prever-movimentos.py` deve ser executado com `Kirin.blend` aberto no Blender. Para codificar os GIFs, ele chama um Python com Pillow; a variável `PYTHON_COM_PILLOW` permite selecionar o executável.

## 7. Diagnosticar defeitos e fechar a entrega

| Sintoma | Teste que isola a causa | Correção |
|---|---|---|
| Parece um boneco de massinha | Veja a pose cinza e de perfil. Procure a mudança de direção no cotovelo. | Redistribua a largura das seções, defina o punho e apoie a sola. Reavalie antes de aumentar a contagem de faces. |
| Rosto funciona só de lado | Gire devagar da frente para três quartos com luz constante. | Mova a área orbital para o plano anterior e revise a ilha facial. |
| Vela, bocal ou chifre parece flutuar | Oculte o efeito e observe o encaixe durante a pose extrema. | Construa a base em contato com a superfície e vincule as partes aos ossos correspondentes. |
| Pata desliza apesar de o osso parecer parado | Meça a geometria deformada de sola e unhas no espaço do mundo. | Corrija pesos, hierarquia ou compensação do apoio; repita no GLB. |
| Marca desaparece de outro lado | Inspecione frente, perfil e costas com textura sem reflexos. | Reposicione a ilha ou dê espaço próprio ao detalhe. |
| Tudo funciona no Blender e a animação some na Godot | Instancie a exportação numa cena limpa e liste as ações do AnimationPlayer. | Confira seleção de exportação, modificador de armadura, faixas NLA, nomes e recursos embutidos. |

Para entregar a próxima criatura, inclua a referência original do projeto, vistas de modelagem, fonte editável, atlas, geradores utilizados, GLB e pelo menos uma prova visual na escala do jogo. Registre triângulos, materiais, ossos, clipes e o teste efetivamente executado. Indique separadamente se foi validada numa cena isolada ou já instalada na campanha. Os modelos de terceiros usados para estudar DW3 não são dependências deste pacote.
