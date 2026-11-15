# Casa do Kael v2

Concept aprovado, ficha de tradução e blockout preparados. Aguardando aprovação dos volumes antes da etapa de pintura. Nenhum asset do jogo foi substituído nesta etapa.

- [Concept](concept/prancha.png)
- [Ficha de tradução](traducao.md)
- [Fachada em escala nativa com Kael](fachada/blockout.png)
- [Contorno sobre o concept](fachada/blockout-sobre-concept.png)
- [Comparação das massas](comparativo-blockout.png)
- [Térreo](interior/blockout-terreo.png) e [planta](interior/planta-terreo.png)
- [Quarto](interior/blockout-quarto.png) e [planta](interior/planta-quarto.png)
- [Medidas verificadas](verificacao-blockout.json)

O gerador `godot/tools/casa_kael_v2_blockout.gd` usa geometria cinza na projeção 64 × 32 e o sprite real do Kael com 70 px visíveis. Confere automaticamente o encaixe do corpo principal no lote e os 136 px de desnível da escada. A renderização foi executada no Godot 4.7.2 com Compatibility. Capturas conferidas visualmente. Colisões, transições entre salas e navegação ainda não foram integradas nem testadas.

Para reproduzir a partir da raiz do repositório no PowerShell

```powershell
& './.local/godot/Godot_v4.7.2-stable_win64_console.exe' --path godot --script tools/casa_kael_v2_blockout.gd --rendering-method gl_compatibility
```

O overlay é uma comparação de proporções em escala uniforme. O concept tem outra câmera e não permite um alinhamento perfeito de todas as quinas com a projeção do jogo.
