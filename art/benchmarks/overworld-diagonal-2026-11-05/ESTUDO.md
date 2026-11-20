# Overworld Soulmonsters — vista elevada em ¾

Estudo de 05/11/2026 da folha enviada pelo usuário. Referência preservada em `referencia.png`; laboratório de inspeção em `index.html`. Trata-se de análise da imagem fornecida, não de identificação confirmada do jogo, autoria ou extração dos arquivos originais. Não reutilizar seus personagens como assets do projeto.

## Conclusão de direção

Nosso overworld precisa de uma interpretação própria de cada Soulmonster para câmera elevada, com identidade concentrada na cabeça e nos grandes volumes. O sprite de batalha aprovado orienta identidade, paleta e materiais, mas sua redução não produz automaticamente uma vista de exploração. É necessário redesenhar a projeção, reorganizar sobreposições e encurtar a anatomia vertical.

Na referência vemos muitas sequências de três poses voltadas para a frente em diagonal, seguidas por três poses de costas em diagonal. Algumas linhas têm outros arranjos. Isso sustenta estudar duas famílias de vistas em ¾; não comprova que o jogo completo usava somente essas direções, nem permite deduzir duração ou ordem de reprodução.

## Medidas verificadas

O PNG recebido mede **600×1169**, com transparência. Há 20 faixas horizontais de conteúdo separadas por linhas vazias. Faixa não equivale necessariamente a espécie, ciclo ou célula de atlas. As medidas abaixo são projeções da ocupação alpha sobre cada faixa, e não tamanhos originais de célula:

| Faixa, y inclusivo | Largura ocupada dos seis grupos, da esquerda para a direita | Leitura visual |
|---|---|---|
| 2–47 | 36, 36, 36, 27, 27, 27 px | Figura ereta dourada; frente mais larga que costas |
| 295–354 | 72, 74, 75, 70, 67, 66 px | Criatura com grande extensão lateral/cauda |
| 551–595 | 37, 37, 38, 29, 29, 32 px | Figura pequena com cabeça/orelhas dominantes |
| 770–837 | 51, 51, 51, 53, 53, 53 px | Figura robusta com grandes volumes arredondados |
| 1088–1149 | 46, 48, 50, 41, 43, 44 px | Figura escura com manto e silhueta vertical |

Consequência: não comprimir todos em uma ocupação idêntica. Há figuras com largura superior a 64 px nesta cópia. A dimensão do arquivo também não comprova que ele foi exportado em escala nativa do jogo. A medição serve para comparar as formas presentes nesta referência.

## 1. Câmera e construção espacial

- Aparecem topo da cabeça, planos superiores de ombreiras, dorso, capacetes e asas. O personagem não está simplesmente de perfil olhando na diagonal.
- A cabeça próxima cobre parte do peito; o ombro próximo cobre parte do braço distante; o pé distante sobe na imagem conforme sua posição no chão. Essas oclusões explicam a câmera melhor que uma rotação do PNG.
- Comprimento do tronco e das pernas na tela é reduzido. Elementos horizontais, como caudas e asas, conservam grande influência sobre a silhueta.
- Frente em ¾ mostra rosto e peito; costas em ¾ reorganiza o foco para nuca, dorso, capa e rabiola. O rosto não deve atravessar a cabeça para continuar visível por trás.
- Uma imagem isolada não determina com precisão o ângulo da câmera. Não impor 30°, 45° ou grade 2:1 por suposição: a compatibilidade final depende da câmera do nosso mapa.

## 2. Proporção e hierarquia de identidade

Não há uma fórmula única de chibi. As figuras pequenas favorecem cabeça/orelhas, enquanto as robustas conservam peito, carapaça ou ombreiras. As alongadas mantêm cauda e focinho. A deformação é seletiva, adequada à anatomia de cada criatura.

Para nós, desenhar a cabeça primeiro e reservar espaço para focinho, máscara, orelhas e olhar. Aumentar a importância relativa da cabeça não significa aumentar olhos ou infantilizar um adulto. No Alvacordo, o olhar estreito, a projeção canina e a gola angular continuam adultos; suas pernas podem encurtar e o tronco pode ficar mais compacto.

Definir três sinais por criatura: um da cabeça, um do volume principal e um de pipa. Um remendo ou cada nó individual podem ser omitidos se competirem com esses sinais. A direção 45% criatura, 45% pipa, 10% pixel/2D mangá é uma relação criativa, não uma porcentagem mensurável de pixels.

## 3. Silhueta e anatomia

A referência distingue figuras por massas: asas abertas ou recolhidas, carapaça arredondada, focinho pontudo, ombreiras largas, manto e grandes caudas. Não depende apenas de mudar a cor.

Manter espaços de leitura entre rosto e arma, pernas e cauda, asa e corpo. Um membro distante pode ficar parcialmente oculto, mas deve reaparecer numa posição coerente. Não abrir buracos de transparência numa articulação para separar as peças. Pescoço, axila, quadril e raiz da cauda precisam ter volume de ligação sob as sobreposições.

O problema dos nossos recortes anteriores não é resolvido somente com uma componente alpha conectada: uma ponte de um pixel pode conectar duas massas que continuam parecendo soltas. Conferir a continuidade anatômica em fundos claros e magenta, quadro por quadro.

## 4. Contorno externo e interno

O exterior tem bordas escuras nítidas, com destaques seletivos nas áreas iluminadas. O resultado não é uma grossa linha preta uniforme em volta de cada pequeno detalhe. Nas partes internas, linhas e sombras de contato separam cabeça/gola, braço/peito e placas sobrepostas.

Aplicação: base de contorno próxima de preto, normalmente 1 px na escala nativa; reforço localizado em oclusões. Compartilhar a borda entre peças em contato, evitando dois contornos que consumam todo o preenchimento. Preservar um plano colorido nas partes finas. Se uma peça virar apenas uma linha preta, simplificá-la ou dar-lhe mais largura.

As diagonais devem ter ritmo e intenção. Não aplicar serrilhado decorativo sobre uma imagem suave. Cada pixel da borda deve ajudar a descrever curva, quina, pelo, papel ou metal.

## 5. Luz, volume e materiais

Nesta folha, pequenos destaques contrastam com recessos escuros e massas de meio-tom. A distribuição sugere luz superior, frequentemente à esquerda da imagem; não foi verificada uma fonte idêntica em todos os personagens. Brilhos não cobrem indiscriminadamente todas as superfícies.

Para a produção proposta, fixar luz superior esquerda da tela, preenchimento em blocos e sombras frias. Marfim iluminado pode ficar quente, teal pode escurecer para azul-petróleo e preto pode receber cinza-violeta. Metal ganha poucos brilhos duros; papel ganha planos mais largos e dobras escolhidas; pelo ganha tufos na silhueta e massas claras/escuras. Não tratar os três materiais com a mesma textura.

Evitar dithering no rosto e ruído de pixels claros em todas as placas. Uma paleta de 24 cores é um bom ponto de partida pelo Alvacordo já aprovado; não é uma contagem demonstrada desta referência nem limite de hardware imposto ao jogo.

## 6. O que a folha ensina sobre movimento

Nas sequências semelhantes, mudam apoio, braços, balanço e acessórios; a espécie, a construção e a escala continuam reconhecíveis. A animação não pode ser apenas uma figura inteira subindo e descendo. Caudas e capas respondem ao corpo, não flutuam sem raiz.

Proposta inicial de ciclo: contato A → passagem → contato B → passagem. Três desenhos podem sustentar a reprodução 1–2–3–2 quando forem planejados para isso. Não afirmar que esta é a reprodução real da folha. Um GIF ou vídeo será necessário para confirmar qualquer leitura de movimento da fonte.

Idle deve ser próprio: respiração discreta, cabeça e rabiola com atraso pequeno, pés apoiados. Para quadrúpedes, escolher marcha coerente com os quatro apoios; para voadores, registrar altura de voo e separar a sombra do corpo.

## 7. Escala e orientação propostas para Soulmonsters

Canvas é área de exportação; ocupação é o corpo dentro dele; escala de mundo é sua relação com Kael e o cenário. São decisões diferentes.

| Categoria | Ponto de partida para piloto, não contrato do jogo |
|---|---|
| Baby | Ocupação de aproximadamente 20–30 px de altura |
| Child | Aproximadamente 30–40 px |
| Jovem | Aproximadamente 40–54 px |
| Adulto | Aproximadamente 48–64 px; extensão lateral pode pedir mais espaço |

Não forçar uma criatura baixa e larga a ser mais alta que todas as children. Comparar em uma régua com Kael e com a família aprovada. Começar o Alvacordo em canvas 80×80 se o enquadramento em 64×64 apertar os arcos; confirmar no piloto antes de fechar o formato. Não inflar apenas o canvas e chamar isso de sprite maior.

Primeiro alvo: frente em ¾ e costas em ¾ de um lado. Derivar os lados opostos por espelho quando a identidade permitir. Assimetrias relevantes precisam de correção, e a luz de tela pode exigir retoque após espelhar. Isso segue a economia já pedida pelo usuário; não gerar vídeos independentes para direita e esquerda. Direções cardinais extras só entram conforme a necessidade do consumidor real.

Âncora é o ponto no chão sob o corpo, não o último pixel da arma ou da rabiola. Um pé distante não precisa atingir a mesma linha y do pé próximo. Cada vista pode ter seu desenho de apoio, mantendo o mesmo ponto de referência espacial no atlas.

## 8. Processo de criação que vamos testar

1. Abrir concept aprovado e listar três sinais de identidade. Usar esta folha somente para câmera, economia de detalhe e acabamento.
2. Desenhar bloqueio de cabeça, tronco, apoios, apêndices e sombra na vista elevada. Conferir frente e costas sem detalhes.
3. Aprovar uma pose frontal em ¾ em resolução nativa, ao lado de Kael. Não animar uma projeção ainda errada.
4. Construir costas em ¾ com os mesmos volumes e cores; conferir a rotação em alternância.
5. Se houver geração de imagem, pedir vistas separadas, mesma câmera e escala, sem texto nem cenário. Tratar o resultado como guia, não como grelha confiável nem sprite final.
6. Desenhar/limpar a grade no Aseprite: contorno, clusters, rosto, peças de pipa e preenchimento das sobreposições. Downscale isolado não é conclusão artística.
7. Criar apoios de caminhada mantendo a anatomia sob as peças; exportar a sequência e revisar em movimento. Preferir poucos quadros bons a muitos quadros inconsistentes.
8. Espelhar lados, conferir assimetrias e highlights. Exportar PNG, Aseprite, atlas com retângulos e pivôs, tempos e prévia.
9. Conferir no cenário antes de integrar: densidade de pixel, escala, obstáculos, ordenação de profundidade e velocidade da passada. O renderer real define os metadados finais; não migrar engine para acomodar a arte.

## 9. Piloto recomendado: Alvacordo

É o teste mais útil porque temos identidade e pose de batalha aprovadas. Preservar cabeça canina adulta com faixa branca e olhos âmbar estreitos; gola marfim angular e armadura teal/marfim; cristal-pipa no peito e dois arcos.

Na frente em ¾: topo do focinho/testa visível, cabeça mais dominante, torso compacto e pés separados pela profundidade. Reposicionar os arcos para não encobrir a máscara. Nas costas: nuca e gola dominantes, dorso armadurado, raiz da cauda e os dois arcos com encaixes coerentes. Não inventar um cristal peitoral também nas costas.

Entregar primeiro as duas poses estáticas e comparação em escala. Depois idle e walk, só após a leitura da câmera funcionar. A versão de batalha 128×128 continua como referência de identidade e acabamento; não será achatada ou rotacionada para fingir a vista superior.

## 10. Critérios de aceite

- A vista elevada é legível pelo topo dos volumes e pelas oclusões, sem depender da legenda.
- Frente e costas representam o mesmo corpo; cabeça, arcos e cauda não trocam de tamanho sem perspectiva.
- Reconhecer adulto e espécie a 1×; preservar rosto e três sinais antes de ornamentos.
- Corpos e peças continuam ligados durante todo o ciclo, sem cortes vazios nas juntas.
- Pés respeitam o chão, com apoio próximo/distante coerente e âncora estável.
- Cores e contornos funcionam sobre branco, magenta, chão claro e vegetação escura.
- Alpha final binário, sem halo; nearest-neighbor e zoom inteiro na prévia.
- Partes móveis não encostam nos limites da célula na pose mais aberta.
- Escala é comparada com Kael e com a família; não normalizar todos pelo maior bounding box.
- Revisão independente e inspeção no jogo antes de chamar a coleção de pronta para produção.

## Limites deste estudo

Foram inspecionadas visualmente a folha fornecida e medidas suas faixas/grupos. Não foram confirmados jogo de origem, ângulo exato de câmera, paletas originais, atlas, FPS ou clips da fonte. As metas de tamanho, paleta e ciclo acima são propostas para um piloto. Não criamos novos sprites nem substituímos assets aprovados nesta etapa.
