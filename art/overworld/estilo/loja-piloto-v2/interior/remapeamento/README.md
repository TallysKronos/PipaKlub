# Revisão do mapeamento interno

A revisão responde à percepção de prateleiras tortas na imagem anterior. As arestas longas das estantes foram pintadas com uma inclinação menor que a parede atrás delas. As medições aproximadas marcadas em diagnostico.png comparam a borda superior da parede (0,49 px verticais por px horizontal), a primeira estante (0,29), a segunda estante (0,29) e o balcão (0,34). São referências escolhidas visualmente sobre a pintura, sujeitas à espessura das bordas.

O novo blockout usa uma única projeção 64 × 32. As arestas de todos os volumes seguem +0,5 ou -0,5 e os montantes são verticais. Os níveis das prateleiras derivam das mesmas coordenadas da base.

## Proposta

- Sala de 18 × 14 células.
- A e B são duas prateleiras paralelas à parede do fundo, de mesma altura e profundidade.
- C segue a parede esquerda e mantém a exposição de pipas.
- D e E seguem o mesmo eixo das estantes para gôndola e caixa.
- F e G reservam os conjuntos de mesa e bancos à direita.
- O eixo central de 3 células liga a porta à frente do balcão.
- A faixa entre o balcão e as estantes do fundo tem 1,3 célula.
- Kael aparece no blockout com o sprite nativo, sem ampliação.

As medidas das estantes, da gôndola e das mesas foram regularizadas nesta proposta. A pintura seguinte deve preservar produtos, carretéis, pipas, terminal, cartas, bancos, janelas e quadros da referência, usando estes volumes como guias.

## Evidências

- [Diagnóstico sobre a arte anterior](diagnostico.png).
- [Planta superior por zonas](planta.png).
- [Blockout com Kael](blockout.png).
- [Comparativo](comparativo.png).
- [Coordenadas dos móveis e verificações geométricas](planta.json).

A checagem confirma as pegadas dentro da sala e a inclinação 0,5 de todas as arestas do eixo u. Circulação e larguras foram conferidas em planta. A caminhada, as colisões e a ordenação com personagens serão conferidas na integração.

Este material corresponde à etapa 1 de revisão. O portão da etapa 1 em documentation/art/PIPELINE-CONCEPT-PARA-JOGO.md pede aprovação dos volumes antes da nova pintura. Após aprovar o mapeamento, repintar o quadro-chave sobre o blockout e reconstruir o kit a partir dele.

## Reprodução

Na raiz do checkout, com o Godot no PATH.

```powershell
godot --path godot --script tools/loja_interior_remapeamento.gd --rendering-method gl_compatibility
```
