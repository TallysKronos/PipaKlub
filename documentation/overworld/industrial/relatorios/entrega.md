# Distrito Industrial — entrega da prévia

Branch `codex/mapa-distrito-industrial`, base `649471de`. Autorização do dono: região independente, sem definir campeão ou revelação narrativa. Não fez merge, push, deploy ou alterações na campanha.

## 1. Arquivos

Brief com plantas ASCII `art/overworld/briefs/distrito-industrial.md`; gerador determinístico `tools/mapa-studio/desenhar-industrial.mjs`; três fontes Tiled e compilados `kronasta-industrial-{a,b,c}`; três entradas novas no índice da prévia. Nenhum mapa antigo redesenhado.

Kit novo `industrial-v1`: fontes geradas, QA de dimensões/alpha/hashes, manifesto e originais. Metal corrugado e concreto 1254×1254; caldeiras recortadas 1536×1024. Geometria nativa de galpão, depósito, contêiner, moldura e usina/chaminé. Caldeiras estáticas, sem rig/animação. Banco existente reutilizado.

`industrial_structures.gd` monta volumes com a mesma pegada de colisão Tiled. `kronasta_forest.gd` permite revestimento industrial e evita árvores/tufos automáticos nesta família. Dois shaders novos controlam textura/alpha. `forest_structures.gd` parametriza cabeceiras da passarela, mantendo valores antigos como padrão; piso metálico e margem neutra só no industrial. Capturador existente reutilizado com planos próprios. Testes de fonte/compilado e percurso, verificador de PNG/hash próprios.

## 2. Conferência automática

```
kronasta-industrial-a
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 50.8% · 3 itens (1 escondidos) · 14 células de rampa · 0 inalcançáveis · 0 degraus soltos
kronasta-industrial-b
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 50.8% · 3 itens (1 escondidos) · 14 células de rampa · 0 inalcançáveis · 0 degraus soltos
kronasta-industrial-c
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 51.7% · 3 itens (1 escondidos) · 14 células de rampa · 0 inalcançáveis · 0 degraus soltos
```

Checagens complementares compartilhadas: partes/ligações, materiais/cotas, largura obrigatória, rampas, pés/chegadas, degraus, bolsões, itens, muretas e moldura. A v−36,0 ↔ B v+36,39; B v−36,0 ↔ C v+36,39, terra0. C possui retorno direto para A. Sem combate ou portão de progressão. Canal B construído, retangular de propósito, água a −12px, recorte e faces pelo mesmo contorno; passarela de4 células com terra nas duas pontas. Sem cachoeira ou poço.

## 3. Capturas

Em `documentation/overworld/industrial/captures/{a,b,c}/{geometria,arte,arte-terreno}`: A45, B56, C46 enquadramentos por versão, **441 PNGs 1280×720**. Manifesto `capturas.json` registra imagem, hash, plano e compilado. Vistas gerais, entradas/saídas, docas, máquinas, cada boca de rampa/escada, cantos de relevo, encontros/pontas de mureta, implantação dos volumes e, em B, margens/cantos/cabeceiras. Sem atores sobre juntas. Sem antes/depois: são mapas novos.

Revisão em pranchas de todas as vistas geométricas e artísticas, complementada por detalhes nativos de escadas, rampas, passarela, galpões e máquina. Não equivale a abrir cada PNG individualmente em tamanho nativo. Uma moldura inicialmente agrupada em segmentos longos ocultava a chaminé pela ordenação; voltou a módulos com ordenação individual, sem desenhar linhas internas de grade. Poste de ponte herdado do Bosque foi parametrizado para as cabeceiras corretas. A rampa lateral foi recuada e a base da moldura leste bloqueada foi rebaixada; a parede não pode cobrir a entrada da rampa. Evidências finais substituem essas tentativas.

## 4. Percurso e testes

Física real da prévia, geometria e arte: A33 destinos/66 viagens/18760 quadros; B34/68/17860; C34/68/18200; **202 viagens e 0 falhas em cada bateria**. Percorre itens/interação, rampas e escada nos dois sentidos; confere bloqueios, pés, seguidor e todas as saídas/chegadas (incluindo C→A). A rota B cruza a passarela. Nenhum teleporte foi usado para alcançar os destinos internos.

Node: 15 testes aprovados (industrial, modelo e conferência). `overworld_checks.gd`:117089 checagens/0 falhas; `morro_map_checks.gd`:9386/0; regressão `bosque_water_checks.gd`:79 pontos de margem protegidos e108 pontos da ponte transitáveis/0 falhas. Saídas0; logs em `testes/`. Geradores determinísticos conferidos contra compilados salvos. Relatório global reescrito pelos testes revertido; kits alheios preservados.

## 5. Itens e história

Nove materiais de catálogo: papel na doca, varetas escondidas atrás da carga e cola na plataforma em cada parte. Descanso apenas descritivo nesta prévia; não concede recuperação. Sem NPC de história, chefe, diálogo canônico ou novos efeitos. A região aprovada ainda não foi anexada à bíblia como novo capítulo. O nome Usina do Vento é cenário/identificação de trabalho, não revelação.

## 6. Pedidos ao integrador

Decidir ligação com mapa de Kronasta e campanha quando apropriado; integrar encontros/NPCs, coleta e persistência usando sistemas oficiais. Preparar importação e export do kit: a importação geral encerrou sem gerar os recursos novos durante processamento de fontes existentes, então a prévia carrega PNGs por `Image.load_from_file` com cache. Um export empacotado precisa incluir as fontes ou configurar o pipeline de importação; não foi testado. Não substituir modelos/colisões por um fundo único.

## 7. Dúvidas para o dono

Sem bloqueio restante para esta prévia. A direção visual nova ainda precisa da avaliação do dono; não marcar assets como aprovados artisticamente. Antes de criar NPCs/campeão ou integrar à história, definir o papel da região. Recomendação: manter independente até avaliar o percurso e o kit.

## 8. O que não foi verificado

Controle físico, sessão humana completa, hardware Steam Deck/Switch, desempenho prolongado, memória/tempo de carregamento em export, batalha, economia, conta e saves. Texturas foram revisadas no cenário, sem prova 3×3 isolada de costura perfeita. Alpha da máquina verificado por amostragem, com shader removendo halo externo; não afirmar PNG pronto sem esse consumidor. Modelo da usina não tem interior. Região não inclui animação de máquinas ou fumaça.

Os testes headless gerais ainda emitem diagnósticos do compilador de shader `_painted_floor` e recursos na saída, distintos das asserções que passaram. Não afirmar logs do motor sem erros, aprovação visual do dono ou integração em produção.
