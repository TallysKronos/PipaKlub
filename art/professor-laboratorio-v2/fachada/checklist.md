# Fachada · etapa 2 · quadro-chave para aprovação

O dono aprovou a fachada da etapa 1 e pediu vê-la finalizada antes do interior. O interior foi considerado apertado e **não está aprovado**; permanece pendente de ampliação.

## Elementos do brief

| ID | Conferência | Presença no quadro-chave |
| --- | --- | --- |
| F1 | [x] Duas abóbadas desniveladas com bordas verde-água espessas | Ala esquerda longa e ala direita mais alta, coberturas separadas |
| F2 | [x] Torre central de vidro alta com losango | Pano frontal com símbolo redesenhado e pano lateral envidraçado |
| F3 | [x] Pórtico laranja recuado e portas de vidro | Entrada central com profundidade e puxadores |
| F4 | [x] Escada, rampa, corrimãos e balizadores | Acessos distintos ao mesmo patamar; conferir percurso na integração |
| F5 | [x] Janelas horizontais nas duas alas com conteúdo | Plantas e caixas em grupos maiores para a escala do jogo |
| F6 | [x] Painel verde-água à direita do pórtico | Faixa vertical sob o encontro da cobertura direita |
| F7 | [x] Pátio cercado, cabine facetada, mesa/computador, maleta e cone | Cabine com cadeira/monitor; mesa separada com maleta dourada e cone laranja |
| F8 | [x] Arco com haste e anemômetro | Dois instrumentos separados no telhado direito |
| F9 | [x] Canteiros floridos e árvores emoldurando | Árvores à esquerda, canteiros dianteiros e jardim lateral direito |

## Acabamento e evidências

- [x] Quadro-chave nativo 768 × 576; envelope visível aproximadamente 720 × 515.
- [x] Arquivo editável `quadro-chave.aseprite`, uma pose, camadas `Base convertida` e `Acabamento de pixel`.
- [x] Comparativo com concept, quadro-chave e captura legada: `comparativo.png`.
- [x] Kael, Rabbito e professor originais em escala 1:1; prancha com cor/cinza, 1× e 2× nearest: `teste-convivencia.png`.
- [x] 31 cores opacas; alpha binário; nenhum pixel opaco sem vizinho ortogonal na verificação.
- [x] Direção de luz do alto à esquerda e linhas internas coloridas por material.
- [x] Revisão independente A/B: B preferida, 8,3/10, sem bloqueio para apresentação ao dono.

A presença dos nove grupos não equivale a aprovação estética. O quadro-chave continua no portão do dono.

## Método, decisões e limites

ImageGen integrado recebeu o próprio blockout aprovado, o concept/recorte do designer e as folhas dos personagens. Primeira saída rejeitada por câmera frontal; segunda saída convertida à régua nativa com nearest e paleta local. O fonte bruto e os prompts estão em `fontes/`.

No Aseprite headless: remoção de variação desnecessária nas coberturas, juntas e símbolo frontal redesenhados, rampas verdes agrupadas, 187 pixels órfãos de cor integrados a massas adjacentes e painel lateral de vidro desenhado na torre, preservando seu volume. A paleta local é um subconjunto da mestra com cores complementares de vegetação/vidro; não substitui a extensão global e o piloto da loja ainda pendentes.

Limites registrados pela revisão: irregularidades miúdas em metais/cerca e maleta com sombra laranja forte. O arquivo é quadro-chave de aprovação, ainda sem separação modular, pivôs ou colisões. O teste foi renderizado em uma prancha isolada no Godot; não é captura da fachada nova integrada no bairro. A coluna “jogo atual” é a captura legada fornecida.

## Próximo portão

Aprovação do quadro-chave exterior antes de cortar kit e montar no mapa. Interior: rever espaço e reapresentar blockout. Nenhuma revelação narrativa adicional foi criada.
