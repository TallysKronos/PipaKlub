# Dispositivo do pipeiro · prompt de concept art

13/11/2026 · pedido ao Codex. Referência de partida enviada pelo dono: manopla grande de placas
com tela azul e uma linha de luz saindo do pulso até o Rabbito. Ela está armadurada demais; o alvo
é outro.

---

Crie o concept art do **dispositivo de pulso dos pipeiros** de SoulMonsters · Elo das Ruínas.

## O que ele é no jogo

- Todo pipeiro de Kronasta usa um. É o aparelho oficial da Liga: no jogo ele substitui a
  "Carteira de Pipeiro" (o documento que hoje registra categorias e emblemas).
- Abre o menu do Kael (equipe, mapa, bolsa, Pipa Dex).
- Tem uma IA que às vezes fala com o Kael: comenta o lugar, avisa de um selvagem, lembra a
  próxima etapa. É uma presença leve, não um personagem humano.
- Nas batalhas, liga a alma do pipeiro à do Soulmonster por uma **linha de luz** (a "linha da
  alma", o mesmo nome do Santuário da Linha da Alma, onde acontece a evolução).
- Nome de trabalho: **Carretel**. O Bando do Cerol usa uma versão corrompida, o **Carretel
  Negro**, que já existe na história e sobrecarrega os parceiros. Os dois precisam parecer da
  mesma família de objetos, com intenções opostas.

## Direção de design

- **Smartphone + peça de pulso, leve.** Uma placa de tela fina, como um celular, presa ao
  antebraço por uma pulseira macia (tecido técnico, elástico, fecho magnético) e duas ou três
  cascas finas. Nada de manopla de placas sobrepostas, cotoveleira ou ombreira. Deve parecer
  algo que um adolescente usa o dia inteiro.
- **O carretel é a alma do objeto.** Na lateral, um carretel pequeno de verdade (o de soltar
  pipa), embutido e girando, que guarda a linha. Na batalha a linha de luz sai dele, não da palma.
- **Materiais de pipa:** varetas finas como estrutura (bambu ou fibra), painéis com textura de
  papel encerado laminado, uma rabiola curta pendurada como chaveiro. Futurista por dentro
  (tela, luz), artesanal por fora.
- **Estados** (mostre todos):
  1. **Fechado:** vira um bracelete discreto; a tela recolhida.
  2. **Aberto:** a tela desliza ou abre como uma asa de pipa (dobra em losango), mostrando o menu.
  3. **Batalha:** o carretel gira, a linha de luz se projeta, a tela mostra o parceiro ligado.
  4. **IA falando:** a tela mostra o rosto da IA, um símbolo simples e expressivo (por exemplo um
     losango de pipa com dois olhos), nunca um rosto humano.
- **Original:** inspiração no espírito de aparelhos de anime de parceiro (Digivice, Duel Disk),
  sem copiar formas: nada de bandeja de cartas, ovo com botões em volta, disco ou anel giratório
  igual. A identidade vem da pipa e do carretel.
- **Legível pequeno:** a silhueta precisa ser reconhecível com 12 px de altura no sprite do Kael.
  Teste reduzindo a prancha.

## Estilo

O mesmo da arte aprovada do jogo: contorno escuro azul-marinho contínuo e nítido, massas amplas de
cor com sombra cel simples, poucas dobras que expliquem construção, sem ruído nem tesselação de
pequenos detalhes. Referências no repositório:

- Kael: `art/characters/kael/concept-refino-2026-11-05/prancha.png` e
  `godot/assets/campaign/portrait-kael-manga-v4.png` (cabelo azul espetado, jaqueta azul).
- Rabbito e o estilo da família: `art/creatures/rabbito-family-v1/ESTILO-APROVADO.md`.
- Paleta do Carretel do Kael: azul-marinho, creme e verde-água do Rabbito, luz ciano.

## Pranchas (entregue em `art/props/carretel-pipeiro/concept-v1/`)

1. `prancha-modelo.png`: frente, lado, trás e topo do Carretel fechado e aberto, com medidas
   relativas ao antebraço do Kael; uma vista explodida (tela, carretel, varetas, pulseira).
2. `prancha-estados.png`: os quatro estados no braço do Kael, em pose; no estado de batalha, a
   linha de luz ligando o carretel ao Rabbito.
3. `prancha-lineart.png`: a prancha 1 só em line art limpa, sem cor nem sombra, traço de
   espessura constante, para virar referência de pixel art e de modelagem.
4. `prancha-variantes.png`: o modelo padrão da Liga; dois personalizados de campeões (Mikka e
   Dona Neve, cada um com cores e um detalhe da personalidade); e o **Carretel Negro** do Bando
   (preto, linha vermelha de cerol, cascas lascadas, a mesma estrutura deformada).
5. `prancha-telas.png`: três telas de interface em close: menu principal, ficha do parceiro e a
   tela de batalha com a ligação; mais a IA em três expressões (neutra, alerta, contente).
6. `icone-hud.png`: o Carretel fechado como ícone, 256×256, fundo transparente, legível a 32 px.

Cada prancha em 2048 px no lado maior, fundo creme liso, com um `prompt.txt` e um `revisao.md`
(o que funcionou e o que não). Faça 2 propostas de forma antes da prancha completa e pare para o
dono escolher uma.
