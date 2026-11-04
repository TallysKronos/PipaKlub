# Clareira do Papel — parte B

Branch `codex/mapa-clareira-do-papel`, baseada em `160b673a`. Cenário isolado no Godot; sem merge ou publicação.

## 1. Arquivos

Brief/planta ASCII e inventário original em `art/overworld/briefs/clareira-do-papel*`; gerador `tools/mapa-studio/desenhar-clareira-do-papel.mjs`; fonte `.tmj` e compilado em seus diretórios existentes. Jardim e Veredas receberam somente coordenadas de chegada. Gerador do Jardim agora deriva conexões da parte B; gerador legado reaplica as duas plantas novas. Testes `clareira.test.mjs`, `clareira_map_checks.gd`; expectativa de chegada no teste do Jardim atualizada. Verificador de capturas aceita ambas as áreas.

Kits existentes reutilizados: terrenos, mata, capim animado, placa, banco, biruta, pedras e pipas ornamentais. Nenhum bitmap ou `kit.json` alterado. As pedras mantêm a arte geométrica simples do kit comum; refiná-las futuramente é trabalho de assets, não de encaixe do relevo.

## 2. Conferência automática

```
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 43.1% · 4 itens (1 escondidos) · 16 células de rampa · 0 inalcançáveis · 0 degraus soltos
```

Gerador usa `auditZeroBreak`: acesso, corredor de duas células, rampas, bolsões, degraus, árvores, muretas, moldura, itens e região. A↔B: terra0, v−/v+; B↔C: terra0, u+/u−. Mato opcional, fora da rota entre saídas. C permanece na versão antiga, sem certificação visual nova.

## 3. Capturas

`documentation/overworld/parque/captures/clareira-do-papel/`: 52 vistas em cada pasta `geometria`, `arte` e `arte-terreno`, total 156 PNGs 1280×720. Plano em `../planos/clareira-do-papel.json` a partir desta pasta; manifesto `clareira-capturas.json` com hashes. Área inteira, entrada/centro/saídas, platôs e cada boca de rampa, canto e ponta de mureta. Não há água, ponte ou escada.

Comparação em `documentation/overworld/parque/comparativo-clareira/`. Mapas 24×16 antes e 48×40 depois: comparação de composição, não de escala idêntica. Revisadas pranchas de todas as vistas geométricas e artísticas, mais imagens nativas de rampas, muretas e roda central. Um recorte indevido no acesso u− levou à troca desse acesso por uma segunda rampa v− na face frontal; evidências finais substituem a tentativa.

Reprodução: `node tools/mapa-studio/desenhar-clareira-do-papel.mjs`; capturador `res://tools/bosque_region_capture.gd`, argumentos `--area=clareira-do-papel --plan=res://../documentation/overworld/parque/planos/clareira-do-papel.json --out=<pasta>`. `KRONASTA_GEOMETRIA=1` para blocagem; `--terrain-only` para retirar peças. Validação: `node tools/mapa-studio/verificar-capturas-jardim.mjs clareira-do-papel`.

## 4. Percurso e testes

Percurso com física real da prévia: 42 destinos, 84 viagens, 20940 quadros, 0 falhas na blocagem final. Cobertura: quatro materiais, interações preservadas, cada célula/pé/chegada de rampa e ida/volta para Jardim e Veredas. Confere bloqueios, pés, seguidor e coordenadas de transição. Arte final: os mesmos 42 destinos/84 viagens/20940 quadros e 0 falhas. `overworld_checks.gd`: 84689 checagens/0 falhas; `morro_map_checks.gd`: 9386 checagens/0 falhas; Node: 19 testes aprovados. Todos com saída 0. Gerador repetido com compilado idêntico. Logs em `testes/clareira-*`.

## 5. Itens e história

Papel escondido entre raízes no platô oeste; varetas perto do mato; cola no descanso; papel no alto da biruta. Nenhum item novo de missão. A rabiola de Nina permanece nas Veredas. Roda limpa reservada ao encontro canônico com Tyler/Rai; esta entrega não inventa falas nem revela o homúnculo.

## 6. Pedidos ao integrador

Encenar Tyler e Rai com seus assets corretos, apresentação como filho do professor e pista do carretel remendado. Validar coleta/encontros/descanso e persistência na campanha real. Conciliar gating por bairros da tabela narrativa com as ligações A/B/C, preservando requisitos existentes. Nenhum desses sistemas foi modificado aqui.

## 7. Dúvidas

Nenhuma definição narrativa adicional foi necessária para a planta. Próximo mapa recomendado: Veredas do Encanamento, preservando Lacertubo, porta das Ruínas e missão de Nina.

## 8. Não verificado

Controle físico, hardware portátil, desempenho prolongado, combate, recompensas online e saves. Não houve inspeção individual nativa de todas as 156 imagens nem asserção de oclusão durante movimento; pranchas e detalhes selecionados foram revisados. Os testes gerais headless podem emitir diagnósticos do shader `_painted_floor` e recursos na saída, já observados na entrega anterior; distinguir esses logs dos resultados de asserções. Não afirmar campanha integrada ou região inteira renovada.
