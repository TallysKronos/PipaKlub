# Soulmonsters — animações regionais de overworld v1

## Escopo e método

O catálogo contém as 194 criaturas das folhas v2: o piloto específico Azulfazo e mais 193 rigs regionais semiautomáticos produzidos no Aseprite. Os desenhos estáticos aprovados continuam preservados.

Cada criatura recebe idle e deslocamento nas vistas SW/NW: oito quadros por ciclo e por vista, 32 quadros no editável, apoio (56,100), células 112×112, cores originais e deslocamentos inteiros. Cada PNG de runtime mede 896×224, com oito quadros na horizontal e duas vistas na vertical. SE/NE são espelhadas pelo consumidor existente; isso também espelha a luz da arte.

O arquivo `anatomias.json` salva o grupo e os parâmetros de cada criatura/vista. Foram inspecionadas as nove pranchas estáticas para separar bípedes, quadrúpedes, voadores, serpentinos, nadadores, multipatas e formas pequenas. O recorte regional usa essas anotações e os limites de cada silhueta. As partes ficam em camadas no `.aseprite` para ajustes futuros. Não são 194 animações exclusivas redesenhadas quadro a quadro, nem foram gerados vídeos.

No idle, tronco/cabeça/apêndices têm fases diferentes e apoios preservados. No deslocamento, bípedes e quadrúpedes alternam grupos de apoio, voadores flexionam asas, serpentinos/nadadores ondulam e multipatas alternam grupos de patas. As articulações mantêm conexões de pixels: emendas internas são fechadas pelas adjacências ortogonais da base; fragmentos não são simplesmente apagados.

## Economia de produção

- Um gerador Aseprite reaproveita sete famílias de movimento, com parâmetros persistidos por criatura.
- QA em lote verifica os 6.176 quadros novos; o piloto tem QA próprio.
- Somente falhas técnicas são regeneradas, com seleção `only` por ID.
- Revisão visual por pranchas de poses e amostras de cada anatomia, com retornos curtos do revisor independente.
- Sem geração de imagens/vídeos adicional, sem pesquisa externa repetida e sem alteração nos PNGs estáticos.

## Arquivos e reprodução

- `index.html`: galeria animada pesquisável; mostra idle/walk e as duas vistas.
- `lote-01.png` a `lote-09.png`: poses-chave em resolução nativa, para revisão.
- `anatomias.json`: anotações editáveis.
- `validacao.json`: QA detalhado por criatura/ciclo/quadro. Aprovação técnica não significa aprovação artística individual.
- `auditoria-aseprite.json`: comparação pixel a pixel entre os editáveis e os atlas, além de dimensões, tags e frames.
- Cada criatura guarda os arquivos em `../soulmonsters-overworld-v2/<id>/animacoes-v1/`.

Ferramentas: `scripts/overworld-xprite-v2/animation-roster.py`, `animate-cast.lua`, `animation-review.py` e `audit-animations.lua`. O primeiro gera as anotações iniciais; preserve overrides ao revisar o arquivo. `animation-review.py --publish` só copia os atlas para o runtime se não houver pendências técnicas. A auditoria Aseprite usa parâmetro `root` apontando para o checkout.

## Integração e limitações

O manifesto de runtime é `godot/assets/campaign/overworld-animations-v1/manifest.json`. A caminhada avança pela distância realmente percorrida pelo companheiro; idle avança por tempo parado. O apoio, espelhamento e limites de oclusão seguem o quadro atual. Retratos e arte de batalha continuam usando seus consumidores próprios.

A revisão independente das sete anatomias deu 7/10 para ciclos regionais funcionais; uma comparação adicional preferiu a correção de emendas de Alvacordo e conferiu Bocobasto. A passada de Aurorastro e o idle de Farpim são discretos; Auriflama flexiona leques de penas, com poses limitadas. Isso não equivale à revisão visual individual de todas as 194 criaturas. Há espaço para poses exclusivas e mais amplitude nas criaturas de maior destaque.

Os resultados finais dos testes e da integração são registrados em `ENTREGA.md`. Integração local, sem commit ou push nesta etapa.
