# Vila Operária — integração do galpão

## 1. Arquivos criados e alterados

Geradores e mapas fonte/compilados B e D, planos de captura e auditorias; `warehouse_story.gd`, `warehouse_tableau.gd`, `warehouse_battle_field.gd`; integração no front-end, checkpoints, validação de encontro, objetivo do galpão, recompensa e inventário. Recortes e manifestos em `art/characters/warehouse-runtime-v1/`; runtime `godot/assets/campaign/warehouse-v1/`. Nenhum kit.json alterado. O índice conserva os IDs anteriores; D continua na mesma região industrial.

## 2. Resultado automático

```text
B: CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 50.8% · 3 itens (1 escondidos) · 14 células de rampa · 0 inalcançáveis · 0 degraus soltos
D: CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 100.0% · 3 itens (1 escondidos) · 16 células de rampa · 0 inalcançáveis · 0 degraus soltos
Cota base +1: 53.3% acima da base. Ligação B↔D conferida nos testes warehouse.
```

D agora usa base +1 para coincidir com o depósito de B; o indicador genérico de 100% inclui essa base e não significa 100% de desníveis internos. A proporção acima da base é 53,3%. Duas escadas continuam subindo v-. A auditoria de D inclui a região A/B/C/D com topologia explícita A↔B, B↔C e B↔D, materiais/cotas/direções e retorno obrigatório. O padrão linear das outras regiões foi preservado. Também inclui corredor largo até todos os eventos; ela detectou o banco originalmente muito perto da borda frontal, que foi afastado.

Node: 13 testes, zero falhas, incluindo fonte/compilado, colisão igual entre blocagem/arte, erro ao inverter rampa ou fechar escada, e ida/volta da soleira B↔D com piso, direção e cota iguais. Godot: história 94/0; fluxo UI nativo 41/0; campanha Vila Operária 60/0; definição 62/0; bairros 452/0; Morro 9386/0; overworld 471787/0. O teste overworld ainda imprime o erro preexistente `custom_samplers` do compilador de shader headless (`view.gd:829`), mesmo com saída zero. A regressão de UI da Feira passou 53/0, mas encerrou com aviso de duas instâncias e um recurso ainda em uso; isso não foi investigado nesta etapa. A importação também imprime o aviso preexistente de safe-save do editor no Windows; não foram desativadas proteções.

## 3. Capturas

Doze capturas nativas do fluxo nesta pasta: Gollia, confirmação do duelo, entrada D, pressão das três rabiolas, proteção de Retalho, Tyler, forma desatada, batalha industrial, recompensa, Bruno liberado e sexto emblema, mais a Agulha na aba Missão da mochila. Sem simular que os resultados de batalha foram obtidos por habilidade humana: o teste injeta resultados terminais para conferir o fluxo.

`mapas/b/{arte,geometria}` e `mapas/d/{arte,geometria}` seguem os planos completos em `documentation/overworld/industrial/planos/`: vista geral, quadros de jogo e detalhes das juntas em zoom 2,3, sem atores nas juntas. São 61 capturas por versão de B e 51 por versão de D (224 PNGs de mapa). Em D, todas foram examinadas nas pranchas de revisão; bocas de escada e entrada também em amostras nativas ampliadas. Em B, conferidos a soleira nova e enquadramentos do fluxo; a geometria anterior não recebeu nova revisão manual individual de cada PNG. As capturas anteriores de `documentation/qa/industrial-d/` são históricas, da etapa isolada anterior; não representam mais a cota atual.

## 4. Percurso

Controlador real nas duas áreas: 38 destinos por parte, 152 percursos de ida/volta, 32140 passos físicos e zero falhas. Pés/seguidor e segmentos livres conferidos. O fluxo UI anda até a porta de B, entra em D, vai ao salão, cancela/reabre o diálogo, atravessa a sequência, entra nos dois encontros, retorna D→B→C, anda até Bruno e registra o sexto emblema. Os quatro primeiros desafios do bairro são uma fixture de pré-condição neste teste; seu serviço completo é testado separadamente. Não foi uma sessão humana com joystick.

## 5. História, itens e persistência

Ordem da bíblia: Cais concluído → Retalho vencido no Bosque → foto lida no arquivo → Gollia Nv.23 com Azulão → galpão → pressão das três rabiolas/Retalho protege Kael → Tyler desata duas almas → Pipa-Dragão desatada Nv.25 → Agulha de desatar → Bruno Nv.24. A aceitação do Carretel é narrada, sem inventar outro parceiro para Gollia. O artefato não substitui o carretel azul do recorte de overworld.

Cada um dos três trechos da cena só é gravado depois de lido/confirmado; cancelar preserva o último trecho concluído. Reiniciar o jogo retoma pelo save, voltando ao salão para continuar. Batalhas suspensas e resultados terminais carregam corretamente. Fuga/derrota preservam a intervenção, não concedem vitória ou item. A entrega da Agulha e a flag exigida por Bruno usam o mesmo recibo atômico do resultado. Uma segunda liquidação não entrega outra Agulha. Sem rabiola/captura/XP de chefe ou loot aleatório nesta missão. Os bancos de B e D recuperam a equipe sem cobrar moedas ou kits e não geram recompensa. O de B funciona antes de abrir a porta, evitando bloqueio após perder para Gollia.

## 6. Próximas integrações

Criar a atuação final (poses/rigs e transformação real) mantendo os designs aprovados; revisar a dificuldade das duas lutas com jogador humano; preparar o cuidado de Retalho no ateliê e o reconhecimento do nó por Assis; implementar a função de remontagem da Agulha antes de oferecê-la como ação. A região continua no catálogo de QA enquanto essa revisão não for concluída. Não foi promovida para publicação pública nem feito deploy.

## 7. Dúvidas para o dono

Nenhuma decisão adicional de história foi necessária. As falas novas são atuação proposta dos acontecimentos já definidos, sujeitas à revisão do dono. Recomenda-se aprovar o fluxo funcional antes da animação final.

## 8. Não verificado

Balanceamento/dificuldade em jogo humano, controle físico, animações finais, rig, transformação anatômica, encenação física de cada nó, Carretel Negro nas mãos de Gollia e pós-cena do ateliê. A forma grande e a desatada compartilham pose estática com escala diferente. A arena usa o modelo de duelo existente, sem habilidade química exclusiva; não afirmar combate de chefe finalizado. Migração de saves públicos antigos não foi ensaiada: D era prévia isolada, e os novos eventos/recibos são locais. Sem merge, push ou deploy nesta etapa.
