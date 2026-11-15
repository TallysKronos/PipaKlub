# Linha & Papel — interior moderno

Quadro-chave da revisão aprovada de volumes. A loja usa estruturas de metal claro, vidro, bases azul-escuras e acabamentos verde-água. O laranja aparece nos encaixes e nas quinas. As mercadorias continuam sendo pipas, linhas, papéis, kits e cartas.

## Arquivos

- quadro-chave.png e quadro-chave.aseprite contêm a arte na resolução nativa de 1120 × 820.
- comparativo.png coloca o blockout aprovado e a pintura com personagens lado a lado.
- prancha-assets.png mostra seis detalhes ampliados em nearest-neighbor para revisar os móveis.
- convivencia-nativa.png e convivencia-cinza.png mostram Kael, Rabbito e Lia na escala dos sprites. As versões -2x permitem examinar os pixels.
- verificacao.json registra paleta, transparência e silhueta.
- fontes/PROMPT.md registra o prompt e as imagens usadas no ImageGen.

## Decisões de design

As prateleiras ganharam montantes metálicos e produtos organizados em módulos. A exposição de pipas usa vidro. A gôndola usa portas inferiores e cobertura transparente. O caixa recebeu vitrine e terminal inclinado. As duas mesas comunitárias têm superfícies escuras com interfaces teal e cartas físicas, acompanhadas de bancos. O piso é cinza-azulado, com paredes creme e painel teal.

A geração usa a distribuição e os volumes do blockout como entrada visual. Sua pintura foi revisada visualmente quanto ao paralelismo e à escala. A geometria exata e os pivôs serão definidos pelo kit e conferidos na integração.

## Conferência

A revisão visual independente atribuiu 9/10 e não encontrou bloqueios no quadro. As prateleiras acompanham as paredes, os móveis conservam a organização do blockout e o corredor permanece reconhecível. A prova posterior com os personagens permite conferir a convivência em escala nativa.

O quadro usa 88 cores da paleta do projeto, alpha binário e zero pixels opacos isolados. O arquivo Aseprite foi salvo em sessão headless, com base e acabamento separados.

Esta é a etapa 2 para aprovação visual, conforme documentation/art/PIPELINE-CONCEPT-PARA-JOGO.md. Após aprovação, cortar os móveis em peças, preparar apoios e atlas e conferir a cena kite-shop. A prancha mostra recortes de detalhe para revisão de arte.

## Reprodução

```powershell
godot --headless --path godot --script tools/loja_interior_moderna_base.gd
godot --path godot --script tools/loja_interior_moderna_revisao.gd --rendering-method gl_compatibility
```

O primeiro comando recria a base para o Aseprite. O segundo usa o quadro-chave exportado do Aseprite e atualiza as pranchas e a verificação.
