# Parque dos Ventos A — Jardim das Pipas

Branch: `codex/mapa-jardim-das-pipas`, a partir de `20c76411`. Somente a parte A foi redesenhada; B recebe apenas a chegada de retorno. B/C continuam com suas plantas anteriores. Sem merge, publicação ou mudanças na campanha.

## 1. Arquivos criados e alterados

- Brief e inventário original: `art/overworld/briefs/jardim-das-pipas.md` e `art/overworld/briefs/jardim-das-pipas-origem.json`.
- Gerador determinístico: `tools/mapa-studio/desenhar-jardim-das-pipas.mjs`; chamado também pelo gerador legado do parque para preservar a planta nova.
- Fonte Tiled e compilado Godot de Jardim; em Clareira somente `chegada_u/v` do retorno.
- Renderização: `view.gd`, `kronasta_forest.gd`, `forest_structures.gd`. Reutilizados terrenos, árvores, frutíferas, mobiliário e capim dos kits existentes, sem modificar nenhum `kit.json`. Pegadas e fio de cerol são decalques geométricos locais, sem nova ilustração externa.
- Capturador com plano opcional, plano do Jardim, verificador de imagens, teste Node e teste de percurso Godot próprios.

## 2. Resultado automático

Saída do gerador:

```
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 44.0% · 4 itens (1 escondidos) · 18 células de rampa · 0 inalcançáveis · 0 degraus soltos
```

Testes finais: `overworld_checks.gd`: 76927 checagens, 0 falhas; `morro_map_checks.gd`: 9386 checagens, 0 falhas; Node (modelo, conferência e Jardim): 16 testes aprovados. Todos com código de saída 0. Logs em `testes/` nesta pasta.

O gerador aplica as checagens adicionais compartilhadas: direção de rampas, degraus, bolsões, largura, árvores, muretas, itens e conexões de região. Conexões A↔B e B↔C conferidas em direção, terra e cota 0. Isso não certifica a renovação visual ou a proporção de platôs das partes antigas.

## 3. Capturas

Em `documentation/overworld/parque/captures/jardim-das-pipas/`: **68 por versão**, em `geometria/`, `arte/`, `arte-terreno/`: **204 PNGs, 1280×720**. Plano em `../planos/jardim-das-pipas.json` a partir desta pasta; manifesto `jardim-capturas.json` registra hashes das imagens, compilado e plano.

Incluem área inteira, entrada, centro, pomar, mirante, platôs, saídas, todas as bocas de rampas/escada, cantos de barranco, encontros/pontas de mureta, coreto e pegadas. Não há água ou ponte nesta área. Sem atores sobre juntas. Vegetação removida na terceira versão para revelar a geometria sob a moldura de mata.

Revisão das 68 vistas geométricas e artísticas em pranchas de contato; abertos também enquadramentos nativos da praça, pomar, mirante, escada, pista e encontro. As miniaturas não constituem inspeção pixel a pixel de todos os PNGs. Comparações em `documentation/overworld/parque/comparativo-jardim/`; mapa anterior 24×16, novo 48×40, portanto a vista geral compara composição, não uma escala idêntica.

Reprodução: gerar com `node tools/mapa-studio/desenhar-jardim-das-pipas.mjs`; executar `res://tools/bosque_region_capture.gd` com `--area=jardim-das-pipas --plan=res://../documentation/overworld/parque/planos/jardim-das-pipas.json --out=<pasta>`. Ambiente `KRONASTA_GEOMETRIA=1` para blocagem; `--terrain-only` para retirar peças. Depois executar `node tools/mapa-studio/verificar-capturas-jardim.mjs`.

## 4. Percurso

Teste `godot/tests/jardim_map_checks.gd` usa o movimento real da prévia, solicitando caminhos distantes e avançando física: **49 destinos, 98 viagens, 30300 quadros, 0 falhas**. Abrange itens, NPC, interações, saídas, células de rampas, pés/chegadas e interior do coreto, ida e volta. Confere segmentos contra bloqueios, projeção dos pés de Kael/seguidor e distância do seguidor ao destino. Confere chegada A→B e retorno B→A. Nenhum save/recompensa real foi modificado. A blocagem também foi percorrida durante a montagem, antes da arte; a bateria final utiliza a arte atual.

Não houve sessão humana com controle, nem asserção automática de oclusão visual durante movimento.

## 5. Itens, pistas e revelações

Quatro materiais alcançáveis: papel escondido no pomar, varetas no mato opcional do pomar, cola no mirante e papel no terraço norte. Assis, bancos e placa preservam IDs/ações originais, assim como os objetos existentes. Mato fora da rota principal, com capim animado, e recompensa que justifica o desvio.

Na praça baixa, pegadas palmadas e fio áspero antecipam Platyx/cerol. A interação descreve o indício sem revelar Tyler. A rabiola de Nina continua em Veredas, sem duplicação de prêmio ou mudança de missão.

## 6. Pedidos ao integrador

- Integrar e testar o cenário no fluxo oficial da campanha com uma conta de teste, preservando os identificadores atuais.
- Encenar Nina e o rapaz distante reparando o apito, conforme a bíblia, com gating/recompensas no código da campanha. Esta entrega não adiciona a cutscene nem revela a identidade de Tyler.
- Conferir encontros, coleta e persistência de materiais no fluxo oficial; aqui somente planta, prévia e metadados são validados.

## 7. Dúvidas para o dono

Nenhuma decisão narrativa nova necessária nesta parte. Próxima etapa recomendada: Clareira do Papel, mantendo o encontro com Tyler no ponto previsto pela bíblia.

## 8. O que não foi verificado

Hardware Steam Deck/Switch, controle físico, desempenho de longo prazo, sessão online, saves, entrega real de recompensas, combate e cutscenes. B/C ainda não receberam este redesenho. Não foi feita inspeção individual em resolução nativa de cada uma das 204 imagens. Os testes gerais headless emitem diagnósticos do compilador de shader em `_painted_floor` e avisos de recursos na saída; os resultados de asserções e códigos de saída são registrados separadamente, sem alegar logs livres de erros do motor.
