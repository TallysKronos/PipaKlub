# Dispositivo do pipeiro · prompt de concept art

13/11/2026 · pedido ao Codex. Referência de partida enviada pelo dono: manopla grande de placas
com tela azul e uma linha de luz saindo do pulso até o Rabbito. Ela está armadurada demais; o alvo
é outro. Revisado no mesmo dia: sem madeira nem carretel físico (o carretel é digital) e
fabricado pela Oakcraft Tech.

---

Crie o concept art do **dispositivo de pulso dos pipeiros** de SoulMonsters · Elo das Ruínas.

## O que ele é no jogo

- Todo pipeiro de Kronasta usa um. É fabricado pela **Oakcraft Tech**, a empresa de tecnologia de
  Kronasta, e é o aparelho oficial da Liga: no jogo ele substitui a "Carteira de Pipeiro" (o
  documento que hoje registra categorias e emblemas).
- Abre o menu do Kael (equipe, mapa, bolsa, Pipa Dex).
- Tem uma IA que às vezes fala com o Kael: comenta o lugar, avisa de um selvagem, lembra a
  próxima etapa. É uma presença leve, não um personagem humano.
- Nas batalhas, liga a alma do pipeiro à do Soulmonster por uma **linha de luz** (a "linha da
  alma", o mesmo nome do Santuário da Linha da Alma, onde acontece a evolução). O **carretel é
  digital**: não existe peça física de carretel; ele é um elemento da interface (um carretel de luz
  que gira na tela ou projetado acima dela) de onde a linha sai.
- Nome de trabalho: **Carretel**. O Bando do Cerol usa uma versão corrompida, o **Carretel
  Negro**, que já existe na história e sobrecarrega os parceiros. Os dois precisam parecer da
  mesma família de objetos, com intenções opostas.

## Direção de design

- **Smartphone + peça de pulso, leve.** Uma placa de tela fina, como um celular, presa ao
  antebraço por uma pulseira macia (tecido técnico, elástico, fecho magnético) e duas ou três
  cascas finas. Nada de manopla de placas sobrepostas, cotoveleira ou ombreira. Deve parecer
  algo que um adolescente usa o dia inteiro.
- **Produto de tecnologia de verdade.** Materiais de eletrônico de consumo: polímero fosco,
  alumínio escovado, vidro, borracha macia, luz de LED. **Nada de madeira, bambu, papel ou peça
  artesanal**, e nenhum carretel físico.
- **O carretel digital é a alma do objeto.** Na tela ou num pequeno projetor de luz na borda, um
  carretel de luz gira e solta a linha da alma. Na batalha a linha de luz sai desse ponto, não da
  palma. Mostre como ele aparece: girando na tela, enrolando e soltando a linha.
- **A pipa está na geometria, não no material:** proporções em losango, recortes e dobras que
  lembram uma pipa (a tela que abre como asa, vincos em diagonal), sem imitar material de pipa.
- **Oakcraft Tech:** crie o logotipo da empresa (original, simples, legível pequeno) e aplique-o
  no aparelho como uma marca de produto real: gravado discreto na casca e na tela de início.
- **Estados** (mostre todos):
  1. **Fechado:** vira um bracelete discreto; a tela recolhida.
  2. **Aberto:** a tela desliza ou abre como uma asa de pipa (dobra em losango), mostrando o menu.
  3. **Batalha:** o carretel gira, a linha de luz se projeta, a tela mostra o parceiro ligado.
  4. **IA falando:** a tela mostra o rosto da IA, um símbolo simples e expressivo (por exemplo um
     losango de pipa com dois olhos), nunca um rosto humano.
  5. **Ligando:** a tela de início com o logotipo da Oakcraft Tech.
- **Original:** inspiração no espírito de aparelhos de anime de parceiro (Digivice, Duel Disk),
  sem copiar formas: nada de bandeja de cartas, ovo com botões em volta, disco ou anel giratório
  igual. A identidade vem da geometria de pipa e do carretel digital.
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
   relativas ao antebraço do Kael; uma vista explodida (tela, cascas, bateria, projetor de luz,
   pulseira).
2. `prancha-estados.png`: os cinco estados no braço do Kael, em pose; no estado de batalha, o
   carretel digital girando e a linha de luz ligando o aparelho ao Rabbito.
3. `prancha-lineart.png`: a prancha 1 só em line art limpa, sem cor nem sombra, traço de
   espessura constante, para virar referência de pixel art e de modelagem.
4. `prancha-variantes.png`: o modelo padrão da Liga; dois personalizados de campeões (Mikka e
   Dona Neve, cada um com cores e um detalhe da personalidade); e o **Carretel Negro** do Bando
   (preto, linha vermelha de cerol, cascas lascadas, a mesma estrutura deformada; uma versão
   pirata, sem a marca da Oakcraft Tech ou com a marca riscada).
5. `prancha-telas.png`: três telas de interface em close: menu principal, ficha do parceiro e a
   tela de batalha com a ligação; mais a IA em três expressões (neutra, alerta, contente).
6. `icone-hud.png`: o Carretel fechado como ícone, 256×256, fundo transparente, legível a 32 px.
7. `oakcraft-tech-logo.png`: o logotipo da empresa em positivo e negativo, fundo transparente.

Cada prancha em 2048 px no lado maior, fundo creme liso, com um `prompt.txt` e um `revisao.md`
(o que funcionou e o que não). Faça 2 propostas de forma antes da prancha completa e pare para o
dono escolher uma.
