# Oficina das Almas — brainstorm de fabricação interativa

22/10/2026 · Proposta para discussão. Não altera o jogo, a migração 024, atributos ou distribuição de itens. A solicitação desta rodada é pensar a dinâmica antes de implementá-la.

## 1. Direção trazida pelo responsável

- Interagir diretamente com a montagem, escolhendo ferramentas, como na referência de Fossil Fighters enviada.
- Cortar, colar e unir a rabiola para dar vida ao Soulmonster.
- Ter diferentes modelos de pipa e graus de raridade.
- Fazer equilíbrio e elo gerarem bônus reais: dois exemplares da mesma espécie podem apresentar desempenhos diferentes por causa da fabricação.

Isso revisa a decisão da primeira oficina, cuja qualidade é apenas um registro visual. A mudança de intenção está aceita neste brainstorm; valores e regras a seguir são propostas, não decisões já aprovadas.

## 2. O que aprender com a referência

Na imagem, a superfície de trabalho ocupa quase toda a atenção. As ferramentas ficam acessíveis na borda; o objeto mostra o efeito da intervenção. O jogador precisa decidir onde agir e com qual ferramenta, observando o material.

Como referência complementar, o [manual oficial de Fossil Fighters Frontier, seção Exploring Dig Sites](https://www.nintendo.com/eu/media/downloads/games_8/emanuals/nintendo_3ds_2/fossil_fighters_frontier/ElectronicManual_Nintendo3DS_FossilFightersFrontier_EN.pdf) descreve uso de martelos e brocas para extrair fósseis sem destruí-los, além de cinzéis desbloqueados ao progredir. Esse manual é de Frontier; não identifica a versão exata da imagem nem comprova suas regras específicas de tempo ou escaneamento.

Nossa adaptação: uma bancada na qual ferramenta, posição, pressão e sequência mudam o resultado. Em vez de quatro cliques que completam peças prontas, o jogador trabalha sobre a superfície real de cada peça.

## 3. Visão da sessão de fabricação

**Escolher alma e molde → estudar a construção → cortar → colar e montar → testar o equilíbrio → unir a rabiola → despertar → comparar resultados.**

O jogador vê a mesma montagem evoluir na bancada. As etapas trocam as possibilidades de interação, sem levar a cinco formulários desconectados. O corpo final conserva a anatomia de pipa da espécie: não nasce um animal comum que depois recebe um acessório.

### Ferramentas principais

| Ferramenta | Gesto e resposta | Decisão interessante | Qualidade observável |
|---|---|---|---|
| Tesoura | Traçar o corte sobre o papel; rebarbas e sobra se separam. | Acelerar em trechos amplos, reduzir velocidade em curvas e preservar abas de colagem. | Precisão do contorno, integridade e preservação de abas. |
| Pincel de cola | Distribuir cola nas faixas de contato; áreas atendidas mudam de aspecto. | Cobrir a região útil sem excesso, respeitando pontos de articulação. | Cobertura correta, excesso e áreas sem aderência. |
| Pinça de montagem | Pegar uma peça, girar, alinhar e assentar na armação. Também prende a rabiola. | Escolher orientação e ponto de fixação; conferir sobreposição antes de pressionar. | Alinhamento, encaixe e posição da amarração. |

Três ferramentas é uma boa hipótese inicial. Para o primeiro protótipo, a tesoura faz todo corte fino; estilete, rolo, espátula e ferramentas especializadas ficam como possibilidades posteriores, evitando começar com uma barra de sete comandos.

Mouse/toque trabalham na peça; teclado/controle podem mover um cursor e acionar a ferramenta com comandos equivalentes. O desafio deve ser definido na escala lógica da bancada e testado por dispositivo. Frequência de amostragem ou taxa de quadros não pode, sozinha, decidir a nota.

### A leitura do molde, nossa alternativa ao scanner

Proposta de nome: **Luz do molde**. Por alguns segundos, revela a estrutura sob o papel, as abas necessárias, regiões que não devem receber cola e pontos seguros para a rabiola. A luz orienta a ação; não executa o trabalho.

Variantes a experimentar:

- Molde comum com indicação permanente, para ensinar a leitura.
- Molde raro com camada de informação que pode ser consultada durante a montagem.
- Consulta com intervalo entre usos ou número limitado por tentativa, caso testar mostre que memorizar é divertido.

Não fechar um limite de usos antes de testar. Se o jogador precisa enxergar a construção para agir com clareza, esconder isso apenas para criar dificuldade pode prejudicar a atividade.

### Tempo

Recomendação: começar com uma bancada de prática sem limite e experimentar **90–120 segundos de atividade** no desafio de fabricação. É um intervalo para teste de ritmo, não duração medida.

O tempo deve parar em pausa, ajuda, carregamento e perda de conexão. Não contar animações de interface ou do despertar contra o jogador. Se o tempo acabar, guardar o estado e oferecer conclusão pelo artesão com resultado básico, ou nova tentativa de trabalho. A alma não desaparece.

Inicialmente, não somar um bônus competitivo extra por velocidade: precisão e execução já geram atributos. O relógio pode primeiro servir a tensão e medalhas de oficina. Se receber peso na qualidade, ele deve ocupar uma parcela pequena dentro do teto de bônus existente, sem criar um multiplicador adicional.

## 4. Como cada fase seria jogada

### Corte

O papel aparece sobre o molde da espécie. O jogador seleciona tesoura e acompanha o contorno. O sistema analisa distância ao traçado, falta de material e abas preservadas. Passar muitas vezes sobre a mesma região não gera pontos extras. Uma pequena rebarba pode ser aparada; cortar para dentro da vela tem consequência diferente de deixar sobra externa.

O formato do desafio vem da espécie: orelhas longas de Rabbito, velas de uma ave e a armadura de uma criatura ancestral não compartilham o mesmo losango genérico. O molde pode ser dividido em peças para não exigir uma curva longa perfeita de uma só vez.

### Colagem e montagem

Cola nas faixas de contato, não no desenho inteiro. As peças aderem à estrutura, formando volume visual e deixando articulações livres. Usar cola em excesso numa dobra móvel reduz a qualidade daquela montagem; um alerta visual ensina o motivo.

A pinça permite alinhar e pressionar. Antes da fixação definitiva, há uma prévia de encaixe; depois dela, é possível corrigir uma peça com custo de tempo ou trabalho. O papel precisa realmente ocupar a geometria que vai aparecer no despertar.

### Equilíbrio

Uma rajada curta percorre a bancada de teste. A montagem inclina, oscila ou tende para um lado. O jogador ajusta o ponto de amarração e, se fizer sentido para o molde, o comprimento do cabresto. Testa novamente e observa a resposta.

Essa fase não deve ter um número universal que sempre se resolve movendo tudo para 50. O ponto de equilíbrio depende da geometria e dos materiais escolhidos; a solução é encontrada pelo comportamento do corpo. Não randomizar um alvo oculto sem pistas visuais.

### União da rabiola e elo

A rabiola é a última peça e contém a alma. O jogador a posiciona no ponto anatômico correto e acompanha uma sequência curta de tensão e soltura, sincronizada com o vento ou com a pulsação visual da alma. A linha encontra seu ponto de manifestação; a rabiola se prende; o olhar responde; o primeiro movimento nasce.

O elo técnico medido aqui precisa ser separado do vínculo afetivo construído durante a aventura. Fabricar mal não significa que o parceiro goste menos do jogador. Termos na ficha podem ser **sincronia de manifestação** para o atributo da oficina e **vínculo** para a relação ao longo do jogo.

## 5. Espécie, molde, material e exemplar

| Camada | O que representa | Exemplo proposto |
|---|---|---|
| Espécie / alma | Identidade, anatomia, personalidade e capacidades próprias. | Rabbito continua Rabbito. |
| Molde | Projeto compatível que determina montagem e perfil de fabricação. | Rabbito com construção leve ou reforçada. |
| Raridade do molde | Complexidade, obtenção e potencial de aperfeiçoamento. | Comum, incomum e raro no primeiro estudo. |
| Materiais | Características da construção e possibilidades visuais. | Papel mais leve, armação mais resistente, linha diferente. |
| Exemplar | O parceiro individual, com sua montagem, histórico, nome, nível e bônus. | Dois Rabbitos feitos por jogadores diferentes. |

Um molde raro não transforma automaticamente uma espécie comum em outra espécie. Se exigir mudança significativa de silhueta ou velas, essa variante precisa de desenho aprovado e de suporte na animação; não esticar a mesma textura.

Também não precisamos permitir qualquer molde em qualquer alma. A compatibilidade pode ser por espécie ou família anatômica. Escolher três moldes de uma criatura é um escopo mais demonstrável do que anunciar dezenas de combinações sem assets adequados.

### Três moldes para explorar no piloto

| Molde proposto | Construção e dificuldade | Tendência de resultado |
|---|---|---|
| Tradicional | Poucas peças amplas e encaixes fáceis de ler. | Perfil equilibrado, boa entrada no sistema. |
| Vela leve | Papel delicado e abas menores, com teste de sustentação mais exigente. | Velocidade e resposta, com margem estrutural menor. |
| Armação reforçada | Mais peças de estrutura e pontos de aderência. | Integridade da linha e resistência. |

Perfil e raridade são eixos separados: pode haver uma versão comum de Vela leve e uma rara do mesmo projeto. Isso ajuda a evitar que uma raridade mais alta seja a única escolha racional para todo estilo de jogo.

## 6. Bônus reais e diferenças entre exemplares

A habilidade na oficina deve ter consequência perceptível e identificável na ficha. Recomenda-se um potencial de fabricação limitado, distribuído entre poucos atributos definidos pelo molde. Fazer bem aproveita esse potencial; fazer mal deixa parte dele sem aproveitamento, preservando o parceiro e suas capacidades básicas.

### Relação entre ação e resultado

- **Corte:** qualidade aerodinâmica, contribuindo para velocidade.
- **Colagem:** integridade da construção, contribuindo para resistência da linha.
- **Equilíbrio:** qualidade de voo, contribuindo para a velocidade ou estabilidade do perfil escolhido.
- **Elo:** sincronia de manifestação, contribuindo para recuperação ou capacidade de energia.

Esses vínculos são propostas. Os atributos atuais da engine são `line`, `energy`, `attack`, `defense`, `speed` e `regen`, além de nível/classes. Começar por velocidade, integridade da linha e regeneração permite testar o conceito com estatísticas que já existem. Controle, estabilidade e tolerância ao vento como novas estatísticas de combate exigiriam regras adicionais; não presumir que já estão implementadas.

### Exemplo numérico de discussão

Para um molde raro, experimentar teto de **+4% em velocidade, +2% em integridade da linha e +2% em regeneração**. Isso é um orçamento ilustrativo; somar percentuais de atributos diferentes não prova que eles tenham o mesmo impacto no combate.

Uma possível regra de cálculo:

- Velocidade: teto × média ponderada de corte (60%) e equilíbrio (40%).
- Integridade da linha: teto × nota de colagem.
- Regeneração: teto × nota de elo.
- Notas entram de 0 a 1; teto e pesos pertencem ao molde, não ao pedido do cliente.

| Mesmo Rabbito, molde e nível | Corte | Cola | Equilíbrio | Elo | Bônus de velocidade | Bônus de linha | Bônus de regeneração |
|---|---:|---:|---:|---:|---:|---:|---:|
| Montagem cuidadosa | 90 | 90 | 90 | 90 | +3,6% | +1,8% | +1,8% |
| Montagem regular | 50 | 50 | 50 | 50 | +2,0% | +1,0% | +1,0% |

Portanto, o primeiro exemplar é melhor pela execução da oficina. Uma montagem com bom elo e corte ruim também pode recuperar energia bem, mas ser menos veloz: o resultado não precisa se resumir a uma nota global.

Na ficha, mostrar valor base, contribuição do nível/classe e contribuição da fabricação separadamente. Não chamar tudo de bônus genético ou rolar valores ocultos no nascimento. O jogador deve entender a causa da diferença.

Raridades poderiam experimentar potenciais totais de 4%, 6% e 8% para comum, incomum e raro. São três parâmetros de protótipo, não uma tabela fechada para épicos/lendários. Os pesos e tetos precisam ser medidos junto de classes, habilidades e progressão; não empilhar multiplicadores sem um limite de fabricação.

### Online

A proposta principal mantém os bônus reais no jogo, inclusive onde esse exemplar for usado online. Não neutralizá-los automaticamente, pois isso removeria parte da intenção expressa pelo responsável.

Mais adiante, um regulamento específico de torneio pode ser discutido, mas não faz parte da aprovação deste brainstorm. Primeiro testar quanto a diferença de fabricação afeta duelos entre parceiros iguais, em ambos os sentidos de vantagem de jogador.

## 7. Aprender, errar e refazer

O jogador pode praticar em papel de treino sem consumir uma rabiola. O artesão oferece uma construção básica para quem quer continuar a história; o melhor resultado vem da execução manual. O botão atual que coloca todos os ajustes no valor perfeito não pode continuar concedendo nota máxima num sistema que pretende premiar habilidade.

Não confundir isso com retirar acessibilidade: cursor por teclado/controle, indicadores claros, ajuste de sensibilidade e alternativas de gesto precisam permitir executar o trabalho. Suporte de entrada não é sinônimo de fabricar automaticamente uma peça perfeita.

Para melhorar um parceiro existente, propor **remontagem**: preservar alma, ID, nome, experiência e história, reconstruindo seu corpo com novos materiais. Comparar a montagem anterior com a nova e permitir manter a anterior. Guardar uma montagem inteira, evitando juntar silenciosamente os melhores atributos de várias tentativas diferentes.

O custo pode ser papel, cola, trabalho ou serviço, a definir. A rabiola não é sacrificada a cada nova tentativa. A oficina deve aprofundar o vínculo com um parceiro, não incentivar abandonar todos os exemplares que não nasceram perfeitos.

## 8. Quinze ideias exploradas

### Valor e progressão

1. **Assinatura de fabricação:** registrar quem montou e qual molde foi usado, distinguindo exemplares pelo trabalho realizado.
2. **Biblioteca de moldes:** descobertas em missões e exploração liberam projetos compatíveis, conectando aventura e oficina.
3. **Remontagem do parceiro:** melhorar o corpo sem perder a alma ou o progresso.
4. **Encomendas do bairro:** NPCs pedem uma construção com características específicas, ensinando estilos de fabricação.
5. **Desafios de artesão:** sessões com ferramentas e tempo definidos para medalhas e reconhecimento, sem tornar tudo um novo multiplicador de poder.

### Experiência e apresentação

6. **Três ferramentas na bancada:** alternância contextual e feedback local de corte, cola e encaixe.
7. **Luz do molde:** estrutura e abas aparecem sob o papel para orientar decisões.
8. **Voo de teste:** problema de equilíbrio é visto no movimento da criatura, não revelado como número-alvo fixo.
9. **Despertar da construção real:** o próprio corpo montado ganha movimento, sem trocar por um parceiro visualmente diferente.
10. **Correção local:** aparar uma sobra ou reposicionar uma peça cria recuperação interessante durante a tentativa.

### Viabilidade e sistema

11. **Moldes em camadas:** contorno, corte, aba, cola, armação, pivôs, amarração e ponto da rabiola pertencem ao mesmo projeto de asset.
12. **Notas calculadas por ação:** medir cobertura e trajetória em vez de aceitar notas prontas enviadas pelo navegador.
13. **Retomada por operação confirmada:** salvar cortes/encaixes em pontos seguros, sem depender de um heartbeat destrutivo.
14. **Renderização das consequências:** máscaras de papel e cola alimentam a prévia sem exigir um PNG novo a cada gesto.
15. **Versão de balanceamento:** guardar parâmetros do molde e bônus do exemplar com revisão explícita, para mudanças futuras não alterarem coleções silenciosamente.

## 9. Cinco prioridades e hipóteses a validar

| Prioridade | Escolha e motivo | Hipótese que precisa de teste |
|---|---|---|
| 1 | Bancada com três ferramentas. Transforma a atividade central e aproveita a referência. | Cortar, colar e encaixar são divertidos em si, com leitura clara das consequências. |
| 2 | Equilíbrio por voo de teste e elo por sincronia. Conecta fabricação à vida da criatura. | O jogador consegue descobrir e melhorar o resultado observando a resposta, sem adivinhar valores ocultos. |
| 3 | Molde e notas independentes gerando bônus reais. Atende à diferenciação entre exemplares. | O benefício é perceptível sem eclipsar decisões de combate, nível ou classe. |
| 4 | Luz do molde e correção local. Dá ferramentas de aprendizado dentro do desafio. | Ajudar a enxergar e corrigir produz evolução de habilidade sem eliminar decisões. |
| 5 | Remontagem preservando o parceiro. Conecta habilidade crescente ao vínculo de longo prazo. | Melhorar o mesmo parceiro é mais desejável do que descartá-lo para tentar um nascimento melhor. |

Biblioteca extensa de moldes, ferramentas raras e campeonatos são expansões. Primeiro comprovar que uma sessão curta de fabricação é boa.

## 10. Primeiro experimento recomendado, quando aprovado

Um Rabbito, uma bancada e dois moldes: tradicional e leve. Três ferramentas; luz do molde; corte e cola com consequências visíveis; voo de teste; união da rabiola. Fazer uma versão sem limite e outra com cronômetro, preservando o mesmo conteúdo para comparar a experiência.

Produzir três construções controladas: fraca, intermediária e excelente. Mostrar de onde vieram os bônus e compará-las num duelo com espécie, nível e classe iguais. Usar também a mesma pessoa alternando os exemplares para reduzir confusão entre habilidade de batalha e qualidade do parceiro.

Observar: troca consciente de ferramenta, compreensão dos erros, vontade de tentar novamente, tempo ativo, influência do dispositivo, utilidade da luz do molde e percepção da diferença entre exemplares. Não usar apenas nota média ou aparência do despertar como prova de que a dinâmica ficou divertida.

### Cuidados de implementação, para a próxima etapa

- Nenhuma pontuação pode ser apenas `nota:100` enviada pelo cliente. O servidor define o projeto e recalcula resultados a partir de ações válidas e dos limites da sessão.
- Validar ordem, área, trajeto, cobertura, tempo e idempotência. Recalcular notas limita adulteração simples, mas não comprova que uma pessoa executou os gestos nem resolve automação por si só.
- Registrar somente ações da bancada necessárias à fabricação; não coletar movimento de mouse fora do jogo.
- Separar geometria de avaliação, apresentação visual e animação. O rig atual não contém automaticamente máscaras de corte ou regiões de colagem.
- Preparar fontes por camada, com abas e raízes suficientes para o movimento. Cortar uma peça não pode produzir uma articulação impossível de animar.
- Preservar reserva da alma e confirmação única no servidor. Os bônus devem acompanhar o exemplar correto, sem trocar seu ID ou se perder após salvar.

## 11. Pontos para fechar na discussão

1. Cronômetro obrigatório, opcional ou reservado a desafios? Minha preferência inicial: aprender sem limite e comparar uma modalidade de desafio cronometrada.
2. Quais dois perfis de molde queremos experimentar primeiro? Tradicional e leve permitem comparar qualidade e comportamento sem precisar produzir muitas variantes.
3. Quais atributos recebem bônus no piloto? Recomendo velocidade, integridade da linha e regeneração, já presentes no combate.
4. O artesão oferece fabricação básica e remontagem? Recomendo ambos, preservando o mérito da montagem manual.
5. Raridade aumenta teto, complexidade ou opções? Recomendo uma combinação limitada de teto e opções, com resultado dependente da execução e sem fazer todo projeto raro ter o mesmo perfil.

Nada nesta rodada foi aplicado ao sistema funcional. A oficina atual permanece com qualidade sem bônus até a proposta seguinte ser aprovada e implementada.
