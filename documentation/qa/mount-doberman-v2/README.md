# Refinamento do encaixe — 01/11/2026

A auditoria inicial foi preservada em `AUDITORIA-INICIAL.md`. Capturas da integração anterior continuam em `../mount-doberman-v1/`; não foram sobrescritas.

## Correções aplicadas

- Nova folha sentada do Kael a partir da anterior, com a perna distante melhor definida e pose menos semelhante a uma cadeira. O avatar a pé permanece intacto.
- Edição dirigida das mãos: abertas e relaxadas nas oito vistas, sem rédeas adicionadas. A segunda edição preservou as posições de quadril e das roupas usadas no encaixe.
- Assento recalibrado nas oito direções e pequeno ajuste da escala do cavaleiro. Comparação explícita com Kael a pé em `kael-scale-comparison.png`.
- Duas camadas complementares usam a mesma textura e o mesmo ponto de quadril: perna distante atrás do corpo; tronco/perna próxima à frente.
- A máscara inicial por meia imagem cortava o casaco. Substituída por polígonos locais que acompanham somente a perna distante. Pontas de casaco permanecem na camada visível.
- Pescoço frontal separado. O cavaleiro inteiro deixou de ser empurrado para trás da montaria.
- Removida a dupla multiplicação da cor no shader, que escurecia a pele e a roupa. Oclusão do mapa da cidade preservada no shader das camadas.
- Corrigidos os recortes E/NE para conservar as rabiolas inteiras sem fragmentos de outras vistas.

## Evidência

Inspeção visual das oito direções ampliadas (`detail-*.png`) e no mapa (`map-*.png`), além de rua, parque e Morro a 1280×720. São capturas do rig no Godot, não montagens de uma imagem de conceito sobre o cenário.

`mount_checks.gd`: 684 verificações, zero falhas na execução nativa. Inclui o comportamento anterior, 96 novas verificações de camadas, sobreposição, alinhamento e máscaras complementares. Os checks técnicos não atribuem perfeição anatômica às imagens.

Regressão: lobby (66 verificações) e acompanhamento na corrida (2.864), sem falhas. Conferência do PCK usa a mesma suíte de montaria com fixture externa e saves isolados.

A composição foi refinada como base estática. Contato visual durante passada, balanço do tronco, alternância das pernas e estabilidade temporal só poderão ser aprovados quando existirem os ciclos. A arte sentada continua sendo manga 2D reduzida; não se declara conversão para a mesma grade de pixel art do Kael a pé. A colisão grande da criatura continua fora deste refinamento de encaixe.
