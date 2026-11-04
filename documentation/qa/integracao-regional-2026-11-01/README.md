# Integração regional — 2026-11-01

Branch local: `codex/integracao-bosque-kronasta`.

Integrados `origin/claude/unificacao` até `1d70c8ea` e `origin/codex/mapa-submerso` até `2cdfb828`. Este último inclui `origin/codex/mapa-gelo` (`3c4ad754`) e a mina de ferro. As alterações locais anteriores foram preservadas em `a4c86f15` e `95df232e` antes dos merges.

## Uso na campanha

Após concluir o treinamento, pressione M e escolha Mina de ferro (4 partes), Geleira de Kronasta (4 partes) ou Recifes de Kronasta (3 partes). As conexões internas respeitam as chegadas autoradas. Os destinos são salvos e reaparecem corretamente na tela de slots e na identidade.

Estas áreas são exploração em desenvolvimento. Não foram inventados chefes, história, oxigênio, natação, mineração nem recompensas automáticas. Os destinos futuros existentes continuam desativados.

Mantidos o zoom autorado e os renderizadores recebidos. O manifesto dos kits acompanha a exportação. Os objetos submersos usam ResourceLoader para funcionar também dentro do PCK.

## Verificação executada

- 19 testes Node: mapas determinísticos, acessibilidade, sustentação, conexões, rampas, fendas e objetos; zero falhas.
- Atlas: 151 verificações, em modo headless e nativo; zero falhas. Capturas 1280×720 e 1920×1080 em `../kronasta-atlas-v1/`.
- Integração regional: 99 verificações de viagens, recarga do save, saídas e chegadas autoradas, carregamento real na campanha e ausência de XP/dinheiro automático; zero falhas.
- Percursos simulados: 944 viagens / 358.500 passos nos 11 mapas; zero falhas. Verificam movimento e sustentação, não equivalem a playtest humano de diversão.
- Corte frontal da mina: 8.841 verificações; zero falhas.
- Layout de recompensa: 1.604 verificações; zero falhas. A captura `victory-unfocused` confirma que a barra de pausa não sobrepõe a vitória após perda de foco.

Capturas desta pasta feitas pelo adaptador real da campanha a 1280×720, com saves isolados. Conferidas visualmente para presença dos kits e da HUD. Não é uma nova aprovação artística de todos os cantos dos mapas recebidos.

Nenhum merge/push em main e nenhum save de produção alterado.
