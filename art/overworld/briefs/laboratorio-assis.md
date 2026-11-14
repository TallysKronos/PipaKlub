# Laboratório do Sr. Assis

O laboratório público continua ligado à Vila do Primeiro Vento. A recepção
leva à mesa do Assis. A partir do centro, o jogador pode visitar o arquivo e
o terminal de estudos, ou seguir para a bancada. O equipamento em losango
da bancada dá continuidade visual à sala de projeção do primeiro parceiro.
O laboratório secreto pertence a uma revelação posterior.

```text
          ARQUIVO  TERMINAL
      janela                  BANCADA
         MESA     ASSIS          |
            +----- circulação --+
            |                caixa
          ENTRADA / VILA
```

O corredor entra pelo limiar e se abre numa área central de circulação.
A bancada é o marco, a faixa no piso indica o caminho, e o terminal marca o
ramal de consulta. Interior plano, em projeção 2:1. O mapa usa a planta e
os gatilhos do interior existente, incluindo o acesso ao arquivo e a saída
para a vila. A fachada segue o lote e o acesso existentes.

Os mestres do Aseprite separam piso, paredes e objetos. A resolução de trabalho
usa a mesma ordem de grandeza do sprite de Kael. O Godot importa PNGs com
filtro nearest, posiciona os objetos pelas coordenadas da sala e usa suas
pegadas para colisão e profundidade.
