# Integração do Distrito Industrial · 30/10/2026

Origem: `origin/codex/mapa-distrito-industrial` (`790f4370`). Destino: `codex/integracao-bosque-kronasta`.

As partes A (Pátio de Cargas), B (Canal das Caldeiras) e C (Usina do Vento) foram incorporadas ao seletor de `godot/scenes/overworld_preview.tscn`. A região permanece independente, como especificado na entrega original: não foi inventada ligação narrativa, chefe, recompensa persistente ou portão para a campanha.

## Resolução dos conflitos

Preservados o controlador atual de exploração, as entradas por nome e coordenadas, os materiais atuais do Parque, o fluxo de campanha e o seguidor que acompanha os passos aceitos inclusive durante corrida. Acrescentados revestimento/volumes industriais, índice A/B/C e parametrização da passarela. Mantida a supressão de marcadores duplicados na campanha. Documentação anterior de integração da campanha preservada.

Os scripts de teste/captura passaram a carregar a view depois dos autoloads; a versão recebida com `preload` antecipava a compilação de `PixelgenSprites` e impedia o avatar de funcionar nesses testes. As texturas industriais foram importadas e agora usam `load` de recursos, com o manifesto do kit incluído no preset de exportação. Não foi produzido nem validado um executável exportado.

## Verificações nesta integração

- Node, fonte/compilado e modelo: 8 testes, sem falhas.
- Percurso real do Distrito: A 66 viagens/18760 quadros; B 68/17860; C 68/18200, sem falhas. Inclui apoio dos pés, bloqueios, seguidor, rampas e saídas/chegadas.
- Integração da campanha do Bosque com save isolado: 114 verificações, sem falhas.
- Corrida/seguidor: 2864 verificações, sem falhas.
- Cuidados: 25 verificações, sem falhas.
- Campanha: 206 verificações, sem falhas.
- Chegadas do Bosque: 11 verificações, sem falhas.
- Margens/ponte do Bosque: 79 pontos de margem protegidos e 108 pontos de ponte transitáveis, sem falhas.
- Clareira: 42 destinos, 84 viagens e 20940 quadros, sem falhas.
- Pátio aberto em renderização nativa 1280×720; captura nova do centro, doca e entrada em `tmp/industrial-integration-captures/`. A doca foi inspecionada. As capturas completas da entrega original continuam na pasta `captures/`; não se afirma nova auditoria visual de todas as juntas.

O teste legado `parque_connections_checks.gd` falha em quatro expectativas de entradas altas e evento 1201 dos mapas antigos (coordenada x=61.5). Seus mapas, script de teste e controlador são idênticos ao HEAD anterior ao merge; esta integração não introduziu a divergência. A campanha atual usa as plantas novas e seus próprios testes. Essa bateria antiga não pode ser tratada como evidência de validação das plantas novas.

A mensagem de safe-save das preferências do editor apareceu durante importação, que terminou com código 0 e gerou as cinco texturas novas. Os percursos e a captura nativa posteriores não apresentaram erros de compilação de script.

A bateria extensa `veredas_map_checks.gd` foi iniciada, mas interrompida nesta rodada após permanecer vários minutos sem conclusão. Não se declara aprovação dessa nova execução. O mapa compilado das Veredas e o controlador de movimento foram preservados; a validação de margens/ponte compartilhadas e a campanha do Bosque acima foram concluídas.

## Como testar

Abra `godot/scenes/overworld_preview.tscn` no Godot, execute a cena e selecione uma das três áreas do Distrito Industrial. Também é possível iniciar com `-- --area=kronasta-industrial-a --art-preview`. Movimento por WASD/setas ou clique; E interage. Nenhum save do jogador foi usado pelos testes.
