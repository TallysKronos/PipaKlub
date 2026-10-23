# Auditoria do quarto de Kael — 23/10/2026

**Resultado: reprovado para aprovação visual e espacial.** A validação anterior demonstrou que os fluxos respondem, mas não que os móveis, paredes, circulação e interações estão alinhados. Os testes passando não sustentam a aprovação da disposição atual.

Auditoria no navegador real, em `http://127.0.0.1:5243/`, conta de teste local Kael. A abertura foi examinada em reprise, sem conceder itens ou alterar etapas da campanha. Também foi inspecionado o código que posiciona os elementos e define a navegação.

## Achados

### P1 — O piso visível não corresponde ao piso caminhável

**Reprodução no navegador:** no passo “Termine seu projeto”, clicar no piso vazio à frente do guarda-roupa faz aparecer “Aqui não dá para passar. Clique no chão livre.” Kael permanece parado, apesar de não existir obstáculo visível no local.

O renderizador desenha um piso de `(350,330)` a `(1400,930)`. A navegação da abertura mantém dois retângulos antigos: `[450,460,850,330]` e `[670,780,200,130]`, mais um bloqueio herdado. Em uma amostragem com espaçamento de 10 unidades dentro do piso desenhado, apenas 42,6% dos pontos são aceitos por `createOpeningRoom().safe()`. Esse número inclui posições visualmente ocupadas por móveis; não representa uma medida exclusiva de chão livre. O clique no trecho vazio é a evidência funcional do defeito.

Exemplo determinístico: `(1200,850)` está sobre o piso desenhado e é rejeitado tanto pela abertura quanto pelo quarto explorável.

Fontes: `src/village-isometric.js` (retângulo do piso), `assets/story/kael-birthday-v1/manifest.json` (walkable/blocked), `src/opening-room.js` (safe/route).

### P1 — Desenhos e bancada possuem destinos antigos, separados dos novos móveis

**Reprodução no navegador:** clicar nos papéis da parede faz Kael andar até um círculo no meio do quarto e apresentar o diálogo dos desenhos, longe dos próprios papéis. Os três círculos de interação não explicam com clareza qual objeto representam.

| Elemento | Âncora visual, coordenadas de mapa | Destino da abertura | Distância projetada entre as âncoras |
| --- | --- | --- | --- |
| TV | `(540,445)` | `(540,510)` | 60 |
| Desenhos | `(1010,330)`, elevados 100 | `(860,510)` | 271 |
| Bancada | `(1100,390)` | `(1050,510)` | 142 |

As distâncias estão em unidades projetadas antes da câmera e não incluem a elevação de parede. Uma distância entre um móvel e o ponto onde o personagem para pode ser intencional; neste caso os círculos no chão e o personagem distante dos desenhos confirmam que a distribuição não está coerente. Ao examinar, o personagem ainda recebe direção fixa `3`, sem olhar para o objeto real.

Fontes: `src/village-isometric.js:17`, `src/opening-room.js:28`, `src/opening-room-client.js:37` e `:88`.

### P1 — Janela praticamente inteira acima da parede

**Observado no navegador:** a janela aparece suspensa sobre o limite superior da parede direita. A moldura não se integra à superfície da parede.

A parede tem altura projetada de 180. O objeto também recebe `lift:180` a partir de um pivô próximo à base da imagem. Isso posiciona a base da janela aproximadamente no topo da parede e coloca quase toda a imagem acima dela. Os desenhos também usam elevação independente e não têm um vínculo geométrico com o plano da parede.

Fontes: `src/village-isometric.js:17`, `:37` e `:48`.

### P1 — Não há um contrato de colisão para os novos móveis

O quarto explorável possui zero objetos na camada `Solids`. A abertura mantém apenas o bloqueio da antiga mesa em `[1080,390,110,150]`. Os novos objetos são desenhados, mas não publicam suas áreas de apoio para a navegação.

Exemplo determinístico: o pé do guarda-roupa `(1350,600)` é rejeitado na abertura, porém aceito no quarto explorável. A física muda entre as duas versões do mesmo quarto. A transparência automática serve para oclusão visual; ela não corrige colisões ausentes.

**Reprodução confirmada no navegador:** entrando pelo mundo, clicar na base do guarda-roupa levou Kael para dentro da área ocupada pelo móvel. O guarda-roupa ficou transparente com o personagem sobre sua base, em vez de impedir a entrada.

Fontes: `assets/world/street-v1/kael-bedroom.tmj`, `assets/story/kael-birthday-v1/manifest.json`, `src/village-isometric.js:49`.

### P2 — Escada, guarda-roupa e enquadramento não formam um quarto habitável

**Observado no navegador:** a escada é um lance isolado em cima do piso, sem abertura, parede, patamar ou conexão que indique para onde desce. O guarda-roupa aparece como uma peça avulsa na frente da bancada, separado da parede. A grande área vazia destaca esses encaixes e deixa os móveis com aparência de peças distribuídas em uma prancha.

Não basta mover cada PNG alguns pixels: é necessário desenhar a planta do quarto e alinhar os objetos a ela.

### P2 — A abertura e o quarto explorável usam plantas diferentes

A abertura desenha o piso em `[350,330,1050,600]`; o quarto explorável usa `[180,220,1300,740]`. A bancada muda de `(1100,390)` para `(1170,430)`, o destino da mesa muda de `(1050,510)` para `(1136,592)` e a escada desenhada fica em `(780,875)` enquanto o portal explorável está em `(784,816)`.

Usar os mesmos sprites não garante continuidade se os limites, posições e interações são definidos separadamente. A comparação no navegador, entrando pela casa e subindo a escada, confirmou a diferença de planta e enquadramento. Kael também é desenhado com altura 120 na abertura e `actorSize:100` no quarto explorável.

## O que respondeu durante a auditoria

- A transmissão da TV continua animada.
- A reprise avança para a exploração do quarto.
- O clique nos desenhos encontra a ação e exibe o diálogo, apesar da posição errada.
- A saída da reprise retorna ao mundo e a entrada da casa funciona.

Isso valida respostas funcionais específicas, não aprova o layout.

## Correção necessária

1. Definir uma única planta do quarto: paredes, chão, entrada/escada, posições e dimensões no solo de cada móvel.
2. Derivar dessa planta a navegação, colisões, pontos de aproximação, destaques, orientação dos personagens e posição das ações narrativas.
3. Colocar janela e desenhos no plano da parede, sem elevações arbitrárias que ultrapassem sua altura.
4. Dar à escada uma abertura e conexão legíveis; encostar o guarda-roupa na parede e liberar a circulação até TV, bancada e saída.
5. Usar a mesma planta na abertura e ao retornar pelo mundo. A câmera pode mudar, a planta não.
6. Revalidar andando por todo o chão livre, tentando atravessar cada móvel, clicando em cada objeto e observando onde Kael realmente para. Verificar a mesma disposição antes e depois da abertura e em uma janela estreita.

Os testes atuais de `village-runtime.test.mjs` cobrem registro dos assets, projeção, câmera e cliques sintéticos. Faltam verificações de aderência à parede, áreas de apoio, colisão de mobiliário e correspondência entre arte e destinos. `npm run audit:world` continua examinando o projeto modular legado e não valida este novo quarto.

## Evidências

- `evidence/village-isometric-v1/audit-bedroom-before.png`: janela acima da parede, escada isolada e guarda-roupa avulso.
- `evidence/village-isometric-v1/audit-drawings-offset.png`: Kael examina os desenhos longe da parede.
- `evidence/village-isometric-v1/audit-invisible-block.png`: erro ao clicar em piso aparentemente livre.
- `evidence/village-isometric-v1/audit-bedroom-world.png`: quarto explorável após entrar pela casa, com planta e enquadramento diferentes.
- `evidence/village-isometric-v1/audit-wardrobe-collision.png`: Kael na área ocupada pelo guarda-roupa, que fica transparente sem bloquear a caminhada.

Esta etapa registra a auditoria. Não houve correção de código, publicação ou mudança de banco de produção.
