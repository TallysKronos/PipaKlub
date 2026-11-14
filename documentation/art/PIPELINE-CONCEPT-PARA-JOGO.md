# Do concept ao jogo · pipeline obrigatório

14/11/2026. Vale para todo concept de cenário que chega do designer (prédio, interior, região).
Motivo: o laboratório do professor saiu "básico e nada parecido com o concept". O concept foi usado
como inspiração, a arte foi desenhada de novo a partir de texto e direto no tamanho final, sem
etapa de volumes nem conferência. Este fluxo impede isso.

**Regra de ouro: o concept é a fonte da verdade.** Não se reinterpreta, não se "simplifica para
caber"; traduz-se para a câmera e a escala do jogo. Se algo não couber, pare e pergunte.

## Etapa 0 · Ficha de tradução (antes de desenhar)

Escreva `traducao.md` na pasta da entrega com:

1. **Elementos obrigatórios:** tudo o que dá identidade (silhueta, volumes, peça central, cores,
   materiais), numerado. Ex.: "E3 · torre de vidro central com o losango".
2. **Elementos que podem simplificar:** detalhes que somem no tamanho do jogo (e como somem).
3. **Paleta extraída do concept** (amostras de cor com hex) e materiais.
4. **Escala:** a altura do Kael em células, a altura de uma porta, de um degrau e de um andar.
5. **Lote no mapa:** quantas células o prédio ocupa e se o lote atual comporta. Se não comportar,
   peça ao Claude para aumentar o lote **antes** de desenhar; nunca encolha o prédio para caber.

## Etapa 1 · Blockout (caixas cinza)

Monte o prédio em blocos cinza, **na câmera do jogo** (isométrica 2:1, a mesma dos mapas), no lote
real, com o Kael ao lado para escala. Sem cor, sem textura. Entregue:

- `blockout.png` e `blockout-sobre-concept.png`: a silhueta do blockout desenhada por cima do
  concept, para mostrar que os volumes batem (alturas relativas, recuos, telhados).

**Portão:** o dono aprova a silhueta. Não passe da etapa 1 sem isso.

## Etapa 2 · Quadro-chave (beauty shot)

Uma imagem final, de alta qualidade, do prédio inteiro na câmera do jogo, pintada sobre o blockout
aprovado e no estilo do jogo (contorno, sombra cel, densidade de pixel dos personagens). Use o
próprio concept como imagem de entrada (edição/img2img) e os recortes de detalhe, não só texto.

- `quadro-chave.png` e `comparativo.png` (concept | quadro-chave | captura do jogo atual).
- `checklist.md`: cada elemento obrigatório da etapa 0, marcado presente ou ausente. **Nenhum
  obrigatório pode faltar.**

**Portão:** o dono aprova o quadro-chave.

## Etapa 3 · Kit modular

Só agora corte o quadro-chave em peças do kit (telhado A, telhado B, torre, pórtico, escada,
rampa, cerca, cabine, canteiros, props do telhado…), cada uma com pegada em células, ponto de
apoio e ordem de desenho. As peças remontadas no jogo precisam reproduzir o quadro-chave.

- Mesma densidade de pixel do Kael (ele tem 70 px de altura na folha; a escala do cenário segue os
  kits aprovados do bairro).
- Paleta da etapa 0; contorno e sombra iguais às peças vizinhas do mesmo mapa.

## Etapa 4 · Integração e conferência no jogo

O Claude monta no mapa, captura no jogo e põe a captura no `comparativo.png` ao lado do concept e
do quadro-chave. Se a captura não bater com o quadro-chave, volta para a etapa 3.

## Interiores

Mesmo fluxo, com dois acréscimos:

- **Planta por zonas** (etapa 0): a planta vista de cima com as zonas do concept (recepção,
  pesquisa, estoque, sala dos fundos…) e a **peça central** marcada. A peça central é desenhada
  primeiro e é a maior do cômodo.
- **Corte de câmera:** as paredes da frente são cortadas (como no concept em corte); o pé-direito
  e os volumes internos (mezanino, pé-direito duplo) aparecem.

## O que nunca fazer

- Gerar de novo só a partir de texto quando existe concept.
- Pular o blockout ou o quadro-chave para "ganhar tempo".
- Encolher, achatar ou trocar a silhueta para caber no lote atual.
- Entregar sem o `comparativo.png` e o `checklist.md`.
