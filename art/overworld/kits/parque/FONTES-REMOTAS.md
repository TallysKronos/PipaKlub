# Parque: subconjunto estático para revisão do Jardim

Origem do conteúdo reutilizado: repositório TallysKronos/PipaKlub, branch de história,
commit `18dec6b87808a45ec23853ff4eb526c37a331b9a`, `art/overworld/kits/parque/`.
Não houve merge nem cópia de código dessa branch. A origem dos arquivos e o estado
de revisão das fontes não foram convertidos em aprovação do novo mapa.

O manifesto inclui os PNGs consumidos pelo renderer atual: terrenos, transições e
peças inteiras. Não inclui os posicionamentos automáticos de vegetação da planta
antiga 24×16, que seriam incompatíveis com a planta nova 40×32. Não liga shaders,
capim animado ou o coreto em camadas. O coreto é um objeto estático bloqueante 4×4
nesta proposta; entrar nele requer outra revisão de colisão e profundidade.

Muros reaproveitam as pinturas de pedra do kit local `morro`, com referência de
origem por arquivo em `importacao.json`. Âncoras e pegadas originais do parque foram
preservadas. Os arquivos fonte de geração não são duplicados integralmente: o
registro fixado no Git e o README original abaixo preservam a rastreabilidade.
Este arquivo não concede uma licença nova nem atribui terceiros como autores.

Reprodução: `python tools/overworld/import_parque_review.py`.
