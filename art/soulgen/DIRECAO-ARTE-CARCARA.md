# Direção de arte dos Soulmonsters — padrão Carcará

Revisão de direção solicitada pelo responsável em 24/10/2026. Referência principal: `keys/carcara/source/layers-generated.png`, especialmente o corpo canônico de `keys/carcara/color-rig/body-reference.png`. A implementação de expressões está em `keys/carcara/color-rig/`. Esta referência governa o **desenho**, além do método de animação.

## 1. O que a análise mostra

Carcará é uma pipa artesanal viva cuja espécie aparece na anatomia. Sua vela central é angular, o capuz escuro cria uma massa grande de valor, o rosto creme é simples, o bico amarelo projeta uma dobra e as asas traduzem penas em folhas de papel. As varetas e os nós explicam a estrutura. Dois pequenos remendos com costura aparente contam que essa pipa já foi usada.

Os olhos são marcas escuras pequenas, sem grandes íris brilhantes, anéis brancos ou reflexos de vidro. A expressão vem principalmente da inclinação das sobrancelhas e do formato dos olhos. No corpo de referência, a largura aproximada de cada olho é da ordem de 5–8% da largura da peça central; é um guia visual medido aproximadamente, não uma regra universal de anatomia. A leitura deve sobreviver sem aumentar os olhos para preencher o rosto.

O acabamento tem contorno escuro, planos de sombra bem definidos e bordas com pequenos degraus próprios da fonte. Há volume por dobras e sobreposição, sem uma superfície inflada e polida. A animação colorida preserva essa fonte; não exige converter toda criatura para uma grade de 96 px ou reduzir a paleta a 15 cores.

## 2. Onde o lote anterior se afastou

Comparação com `keys/basic-color-v1/review-lineup.png`:

| Elemento | Carcará aprovado | Lote anterior a revisar |
|---|---|---|
| Olhos | Pequenos, escuros, sobrancelhas gráficas | Grandes íris, muito brilho, anéis claros |
| Hierarquia | Vela, espécie e construção dominam | Rosto e olhos dominam |
| Material | Papel dobrado, varetas, costuras e remendos | Superfícies limpas, acabamento de mascote polido |
| Volume | Planos e dobras angulares | Curvas arredondadas e realces excessivos |
| História visual | Remendos integrados à vela | Poucos sinais de fabricação e reparo |
| Espécie | Bico e penas-papel reconhecíveis | Algumas formas ficaram genéricas ou abstratas |

O lote anterior tem preparação técnica de rig, mas **não está aprovado na direção artística**. Testes de alpha, pivôs e continuidade não demonstram consistência de estilo. Seus recortes e coordenadas não são um desenho canônico para a próxima geração.

## 3. Regras de desenho

### Silhueta e anatomia de pipa

- Começar pela espécie e pela vela: a silhueta precisa funcionar com o rosto escondido.
- Transformar anatomia em construção: penas de papel, orelhas de vela, nervuras de vareta, juntas amarradas e rabiolas. A linha é o método de manifestação, não um substituto dessa anatomia.
- Usar formas assimétricas quando a perspectiva pedir. Preservar vista e orientação entre corpo, peças e expressões.
- Manter poucos traços dominantes por espécie. Não repetir diamante, joias ou o mesmo conjunto de acessórios em todos.

### Rosto e expressão

- Olhos pequenos, escuros, gráficos e foscos. Evitar grandes íris coloridas, múltiplos brilhos, grandes áreas de esclera e aparência de olho de vidro.
- Usar sobrancelhas ou dobras superiores para intenção. Uma criatura calma pode ter marcas suaves; não dar a todas o semblante agressivo do Carcará.
- Nenhum aumento dos olhos ou da cabeça durante golpe, dano ou vitória. Expressões mudam dentro de janelas faciais registradas.
- Dano: olhos apertados e reação breve. Golpe: foco e sobrancelhas baixas. Vitória: arcos simples e gesto corporal. Boca pequena, quando fizer sentido para a espécie.
- Espécies com bico expressam alegria principalmente pelos olhos e postura; não adicionar uma boca humana separada sob o bico.

### Bicos e outras marcas de espécie

- **Aves têm bico visível**, articulado visualmente como papel dobrado, com uma face iluminada e outra sombreada. O bico deve ser reconhecível em miniatura.
- O tamanho e a curvatura distinguem a espécie. Não copiar o bico de rapina do Carcará para toda ave.
- Coelhos mantêm focinho pequeno e orelhas; formas vegetais mantêm sua linguagem de folha. Não acrescentar bicos a criaturas que não sejam aves.
- As características de cada espécie devem constar da ficha antes da geração. Um nome ou uma cor não basta para decidir anatomia automaticamente.

### Papel, remendos e armação

- Papel com dobras, recortes e sobreposições legíveis. Varetas nas bordas ou nervuras estruturais; nós nas conexões que realmente precisam deles.
- Incluir remendos de papel na família básica como parte da fabricação e da história. Como ponto de partida, um a três remendos pequenos, com distribuição própria por espécie.
- Remendo acompanha o plano da vela: muda de perspectiva com ela, tem espessura discreta e poucos pontos de costura visíveis. Não é um adesivo flutuando ou uma joia.
- Não usar remendos como disfarce de recorte ruim ou fenda da articulação. Não colocar um remendo sobre olhos, bico ou raiz móvel sem uma razão de desenho.
- Desgaste deve ser localizado e intencional. Evitar sujeira, ruído ou textura espalhada que prejudique a leitura em tamanho de jogo.

### Cor, luz e borda

- Preservar a família de cor de cada identidade, mas organizar em poucas massas dominantes: luz, meio-tom, sombra e contorno.
- Priorizar contraste entre rosto, vela e marca da espécie. Brilho metálico ou dourado fica restrito a pequenos detalhes que já façam parte do personagem.
- Sombra facetada por dobras; evitar gradientes de plástico, brilho de gel, aquarela lavada ou realce branco em todas as bordas.
- Comparar a dureza do contorno e a densidade de detalhes com a fonte do Carcará. Não acrescentar serrilhado artificial ou reduzir a resolução para simular esse acabamento.

## 4. Aplicação ao próximo lote

| Criatura | Identidade a preservar | Correção de direção |
|---|---|---|
| Mata verde | Vela-folha, nervuras e cipó | Reduzir os olhos; fazer nervuras parecerem estrutura e papel sobreposto; acrescentar reparos de papel coerentes com a folha. Manter anatomia vegetal. |
| Azulão | Vela azul/creme, asas e rabiola de nuvem | Simplificar o rosto e os brilhos; registrar explicitamente a espécie na ficha. Se representado como ave, incluir bico curto próprio, sem copiar o gancho de rapina. |
| Raio de sol | Papel amarelo/laranja, asas sanfonadas e rabiola dupla | Trocar o aspecto de joia polida por papel dourado dobrado; olhos escuros pequenos, reparos e nós estruturais. Manter identidade solar, sem inventar uma ave. |
| Rabbito | Coelho creme/turquesa, orelhas-vela, focinho e laços | Reduzir os olhos azuis brilhantes a marcas escuras menores; preservar o focinho; reforçar corpo de papel com dobras e remendos. Manter a delicadeza sem aparência de pelúcia. |

As mudanças são de arte. Não alteram raridade, aquisição, atributos, bônus ou regras de combate. Esta tabela é uma orientação de revisão, não afirma que novas imagens já foram produzidas.

## 5. Ordem de referência e produção

1. Pedido atual do responsável define a intenção.
2. Carcará aprovado define estilo de desenho, expressão, material e acabamento.
3. Fonte anterior da espécie define identidade: paleta, anatomia e traços próprios, adaptados à direção atual.
4. Contrato do Soulgen define recortes, pivôs, parentesco e ações. Ele não decide a aparência.

Na próxima geração, **não descrever o Carcará como referência apenas de layout**. Inspecionar e fornecer sua imagem como referência principal de arte. Fazer primeiro uma pose completa representativa da espécie, compará-la lado a lado com ele na mesma escala e só então decompor em peças. A validação interna pode prosseguir sem pedir permissão a cada etapa, dentro do pedido do responsável.

Depois do desenho coerente: gerar peças com raízes completas e sobreposição, medir os recortes reais, registrar as expressões sobre uma peça canônica e refazer pivôs para a nova geometria. Não reaproveitar coordenadas antigas apenas para evitar trabalho.

## 6. Bloco de prompt obrigatório

> Referência A, Carcará aprovado: governa o ESTILO DE ARTE, não apenas o layout. Referência B: governa a identidade e a anatomia desta espécie. Criar uma pipa artesanal viva de papel facetado, varetas, nós e rabiola, com contorno escuro e sombra por planos de dobra. Olhos pequenos, escuros e gráficos, expressão por sobrancelhas e postura; sem íris enormes ou reflexos de vidro. [Característica anatômica da espécie; incluir bico dobrado somente se for ave.] Remendos de papel com poucos pontos de costura, aderentes ao plano da vela e em posições próprias deste personagem. Preservar [paleta, silhueta e traços da espécie]. Não usar plástico polido, pelúcia, mascote de olhos gigantes, aquarela ou joias ornamentais genéricas. Arte colorida com transparência real, sem cenário, texto ou efeitos que escondam o desenho.

Para peças e expressões, acrescentar o contrato de rig de `DIRETRIZES-RIG-COLORIDO.md`. Registrar prompt completo, referências e versão; preservar as fontes anteriores como histórico.

## 7. Critério de revisão visual

- [ ] Ao lado do Carcará, parece feito pelo mesmo processo artístico?
- [ ] Com os olhos escondidos, espécie e construção continuam reconhecíveis?
- [ ] Olhos são discretos na composição, sem perder expressão em 96–128 px?
- [ ] Aves têm bico próprio e legível; outras espécies mantêm sua anatomia?
- [ ] Papel, varetas, nós e remendos têm função e perspectiva coerentes?
- [ ] A cor cria planos de papel, com controle de brilho e textura?
- [ ] Expressões preservam alpha, silhueta e pixels fora das janelas registradas?
- [ ] As juntas permanecem conectadas nos extremos das cinco ações?
- [ ] Corpo e peças mantêm a mesma vista, escala e luz?

Revisão de estilo vem antes do aceite técnico do rig. Resultados técnicos e aprovação artística devem permanecer registrados separadamente.
