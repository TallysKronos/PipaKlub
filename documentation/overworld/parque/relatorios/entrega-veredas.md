# Veredas do Encanamento — Parque dos Ventos C

Branch `codex/mapa-veredas-do-encanamento`, a partir de `5549f21f`. Construção da prévia Godot; sem merge, push ou publicação.

## 1. Arquivos

Brief e inventário original: `art/overworld/briefs/veredas-do-encanamento*`. Gerador: `tools/mapa-studio/desenhar-veredas-do-encanamento.mjs`; fonte Tiled e compilado mantêm IDs e `park-veredas`. O gerador legado agora reaplica as três partes novas. Não foram redesenhados Jardim/Clareira, nem alterados kits alheios.

`forest_structures.gd` aceita canal sem poço/cachoeira: contorno de poço vazio é ignorado e queda só é criada quando declarada. O caso anterior do Bosque mantém sua queda. `view.gd` oferece acompanhamento por passos realmente percorridos, ativado somente em `forest.followTrail` nas Veredas: resolve a troca de desvios do seguidor junto ao rio; não muda o sistema da campanha. Testes e verificador de capturas acompanham a área.

Arte reutilizada: terrenos, água clara, comum e Veredas (canos, capim de margem, buritis). Nenhum bitmap ou `kit.json` novo. Pátio e muretas usam geometria derivada da mesma planta; ponte e margens são nativas.

## 2. Conferência automática

```
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 41.2% · 4 itens (1 escondidos) · 18 células de rampa · 0 inalcançáveis · 0 degraus soltos
```

Inclui largura de rota, rampas v−, pés/chegadas, bolsões, degraus, muretas, árvores, moldura, itens e conexões A/B/C. B u+(47,8) ↔ C u−(0,13), terra0. Quatro materiais novos e cinco baús existentes alcançáveis. Mato opcional, fora da rota obrigatória. Canal a −6 px, contorno curvo compartilhado entre recorte/margem/água; três células de largura na ponte, terra firme nas duas cabeceiras. Sem poço ou cachoeira nesta parte.

## 3. Capturas

`documentation/overworld/parque/captures/veredas-do-encanamento/`: 73 vistas em cada uma de `geometria/`, `arte/`, `arte-terreno/`, **219 PNGs 1280×720**. Incluem geral, entrada/saída, platôs/pátio, bocas de rampa/escada, cantos, muretas, cabeceiras, tabuleiro e margens. Sem atores sobre juntas; terreno descoberto revela as bordas cobertas pela moldura de mata. Plano em `../planos/veredas-do-encanamento.json` a partir desta pasta, manifesto de hashes `veredas-capturas.json`.

Antes/depois em `documentation/overworld/parque/comparativo-veredas/`. Antes 50×32 e depois 52×44; vista geral compara composição, não escala idêntica. Pranchas de todas as vistas e detalhes nativos selecionados revisados; não houve inspeção individual nativa de todas as 219 imagens. Capim da margem foi reagrupado fora da terra obrigatória, corrigindo a faixa repetida observada na primeira montagem.

Reprodução: `node tools/mapa-studio/desenhar-veredas-do-encanamento.mjs`; capturador `res://tools/bosque_region_capture.gd` com `--area=veredas-do-encanamento --plan=res://../documentation/overworld/parque/planos/veredas-do-encanamento.json --out=<pasta>`. Ambiente `KRONASTA_GEOMETRIA=1` para blocagem; `--terrain-only` para retirar peças. Manifesto: `node tools/mapa-studio/verificar-capturas-jardim.mjs veredas-do-encanamento`.

## 4. Percurso e testes

Blocagem: **72 destinos, 144 viagens, 61500 quadros, 0 falhas**. Inclui NPCs, cinco baús, quatro itens, interações, todas as células da ponte e de rampas/escada, pés/chegadas, ida/volta à Clareira. Verifica bloqueios, chão recortado sob os pés, seguidor e projeção. A primeira tentativa encontrou quatro falhas de acompanhamento; aumentar a espera não resolveu. A trilha de passos aceitos corrigiu o problema sem teleporte ou passagem por água. O teste permite até quatro segundos para o seguidor alcançar o destino, sem reduzir os critérios de colisão.

Arte: 72 destinos, 144 viagens, 61500 quadros, 0 falhas. Node: 23 testes aprovados; `overworld_checks.gd`: 88039 checagens, 0 falhas; `morro_map_checks.gd`: 9386 checagens, 0 falhas. Todos com saída 0. Gerador repetido com compilado idêntico. Logs em `testes/veredas-*`. Coleta, baús e transições são verificados na prévia, sem entregar recompensas ou tocar saves reais.

## 5. Itens e história

Preservados todos os IDs/ações, incluindo `parkBoss`, `veredasNina`, `veredasTail`, `veredasTrace`, `veredasPipes`, descanso e cinco identidades de baú. Papel escondido nas raízes, varetas no mirante, cola na margem sul e papel no pátio são materiais do catálogo. A rabiola de Nina continua sendo uma única interação existente, não um novo prêmio duplicado. O conjunto de canos marca o pátio do guardião.

## 6. Pedidos ao integrador

Integrar a planta e validar batalha/coleta/descanso/persistência com uma conta de teste. Encenar Grampo, vibração da Rabiola Antiga e revelação da porta das Ruínas conforme a bíblia. O acesso atual continua a interação dos canos: esta entrega não inventa um destino de Ruínas nem ativa passagem para uma cena sem contrato. Implementar atalho direto C→A condicionado à vitória, usando estado da campanha; o retorno interno pela ponte já funciona. Replicar o acompanhamento por trilha no controlador oficial se este tiver o mesmo problema da prévia.

## 7. Dúvidas

Nenhuma definição narrativa nova necessária à planta. Para a próxima região, seguir a bíblia e confirmar nomes/destinos antes de construir áreas sem contrato definido.

## 8. Não verificado

Controle físico, hardware portátil, desempenho prolongado, combate oficial, recompensas, save online, cutscenes e abertura real das Ruínas. Não houve teste humano completo nem asserção de oclusão visual em movimento. Gating por bairros e atalho pós-vitória exigem integração, portanto o cenário pronto não significa campanha completa. Diagnósticos de shader `_painted_floor` e recursos na saída dos testes gerais são registrados separadamente das asserções; não alegar logs limpos do motor.
