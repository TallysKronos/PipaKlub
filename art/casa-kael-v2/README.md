# Casa do Kael v2

Concept, ficha de tradução e blockout preparados. A correção dos volumes da entrada foi aceita para avançar à candidata de pintura da fachada. Nenhum asset do jogo foi substituído nesta etapa.

## Atualização da fachada

O dono autorizou avançar após a correção da entrada. A candidata de pintura da fachada está em [quadro-chave.png](fachada/quadro-chave.png), com [comparativo](fachada/comparativo.png), [prévia com Kael](fachada/previa-com-kael.png), [checklist e limitações](fachada/checklist.md) e [prompt integral](fachada/PROMPT.md). Aguardando aprovação visual desta candidata antes do kit. A fonte está salva também em Aseprite. A limpeza na grade nativa e a modularização continuam pendentes, assim como a pintura dos interiores.

## Recortes em escala nativa

O dono autorizou continuar a partir da pintura. Foram preparados [sete recortes complementares](fachada/kit/README.md), com [manifesto](fachada/kit/kit.json), [remontagem](fachada/kit-remontado.png), [contato das peças](fachada/kit-contato.png) e [convivência em 1×](fachada/kit-convivencia.png). O QA registrou zero lacunas, zero sobreposição e alpha binário. A posição do portão e a altura da porta precisam ser calibradas ao blockout antes da integração. O jogo ainda usa a casa anterior.

## Integração aplicada

A calibração dos acessos e a substituição da fachada foram autorizadas e executadas. A casa v2 agora é montada na Vila. Veja o [relatório da integração](fachada/integracao/README.md), o [comparativo](fachada/integracao/comparativo.png) e as [31 verificações sem falhas](fachada/integracao/qa.json). O portão está aberto no caminho existente, a soleira abre o interior e a saída preserva HOME. Os parágrafos anteriores registram as entregas históricas. A pintura dos interiores v2 permanece pendente.

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

## Revisão da entrada

Corrigida a oclusão do muro e do canteiro laterais, antes desenhados sobre a marquise. O caminho agora é desenhado antes do prédio. Bicicleta refeita com quadro e rodas apoiados na cota do jardim. Fachada e comparativos foram recapturados no Godot. Permanece na etapa de aprovação de volumes.
