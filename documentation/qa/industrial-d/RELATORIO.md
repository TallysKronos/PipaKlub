# Vila Operária D — cenário do galpão

## 1. Arquivos

Brief `art/overworld/briefs/kronasta-industrial-d.md`; gerador `tools/mapa-studio/desenhar-industrial-d.mjs`; fonte TMJ e compilado `kronasta-industrial-d`; registro no índice de prévias; plano e auditoria em `documentation/overworld/industrial/`. Montagem reutiliza o kit industrial, com extensão optativa `interior` para fundo preto e corte de paredes, `closedStairs` para fechamento dos prismas dos degraus. A/B/C não foram regeneradas nem modificadas. Nenhum kit.json foi alterado.

## 2. Conferência automática

```text
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 1 avisos
Platô 53.3% · 3 itens (1 escondidos) · 16 células de rampa · 0 inalcançáveis · 0 degraus soltos
AVISO [Partes da região] Prévia isolada: ligações da região NÃO verificadas.
```

O verificador mantém a exigência regional por padrão. Somente esta prévia solicita explicitamente auditoria local, que imprime o limite acima. Teste negativo garante que a mesma área reprova sem essa opção. Rampas u+/v+, mureta atravessando escada, bolsão, degrau, peça/evento sobre acesso e corredores são conferidos. O teste exige rota larga até todos os eventos, além do percurso físico abaixo. Sem árvores ou água neste interior.

Node: 11 testes, zero falhas (`industrial-d`, `industrial`, `model`). Godot: `morro_map_checks.gd` 9386 verificações, zero falhas; `overworld_checks.gd` 471772, zero falhas. Este último continua imprimindo o erro preexistente do compilador de shader `custom_samplers` no renderer headless, em `view.gd:829`; não é um log livre de erros. Código de saída zero.

## 3. Capturas

`arte/` e `geometria/`: 42 PNGs de 1280×720 por versão. `area-inteira.png`, `entrada.png`, `centro.png`, `salao.png`, `recebimento.png`, `plataforma.png`, `ramal-oeste.png`; demais imagens cobrem todos os cantos de desnível, oito faixas de escada com pé/chegada e as pontas/encontros de mureta enumerados pelo plano. Juntas com zoom 2,3, sem Kael, seguidor ou HUD. Pranchas `revisao-*.jpg` são miniaturas para conferência, não substituem os PNGs.

Inspeção em pranchas e amostras nativas ampliadas. Corrigidos: muretas na chegada da escada superior; triângulos vazios sob degraus; base da parede oeste flutuando sobre o piso baixo; continuidade das faixas de janela entre paredes com bases em cotas diferentes. Nova área, sem antes/depois de mapa substituído.

## 4. Percurso

Teste `INDUSTRIAL_AREA=kronasta-industrial-d` com o controlador real: 37 destinos, 74 percursos de ida/volta e 12220 passos físicos, zero falhas. Inclui eventos, itens, células de rampas, pés e patamares. Verifica trajetória sem atravessar bloqueios, pés no suporte projetado e seguidor acompanhando. Não representa sessão humana com joystick. Repetido após os ajustes de suporte das paredes e escadas.

## 5. Itens e história

Três itens existentes: papel-seda, vareta-bambu escondida e cola-reparo. A plataforma dá vista para o salão, a carga delimita o recebimento e mantém espaço de recuo. A interação central avisa que a sequência ainda não está ativa. Nenhum ator provisório, nova revelação, alma libertada, recompensa de chefe ou flag de vitória foi concedido. A regra de Bruno continua preservada.

## 6. Próxima integração

Construir entrada física B↔D com porta/soleiras e cotas compatíveis; registrar checkpoint e acesso na campanha; colocar Gollia, Retalho, Tyler e as duas apresentações aprovadas da Pipa-Dragão; implementar sequência, interrupção/retomada, derrota, vitória e recibo da Agulha de desatar. Testar balanceamento e retorno à campanha antes de publicar a região. Não confundir o registro no índice de mapas com integração ao percurso da conta.

## 7. Dúvidas

Nenhuma decisão nova de história necessária para o cenário: a sequência segue a bíblia. A integração ainda deve preservar os designs aprovados dos atores, sem substituí-los por placeholders.

## 8. Não verificado

Ligação física entre B e D; acesso normal por save; cinemática, transformação, batalha e recompensas; retomada durante o confronto; controles humanos/gamepad e oclusão de personagens junto à parede alta. As capturas deliberadamente removem atores para conferir juntas. O palco está construído e testado localmente; a sequência narrativa não está implementada. Sem push, merge ou deploy nesta etapa.
