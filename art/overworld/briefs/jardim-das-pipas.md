# Jardim das Pipas — brief de aprofundamento da missão de Nina

**Histórico, superado pela revisão regional A/B/C.** O plano atual está em `parque-dos-ventos-abc.md` e as dimensões/posições abaixo descrevem o primeiro estudo 40×32, não a planta atual 60×44. Preservado para rastrear as decisões, não para regenerar o mapa.

Lote: `codex/mapa-mundi`. Planta proposta em 29/10/2026; mapa-múndi autorizado pelo “faça” do criador. Não equivale à aprovação visual final da área.

**Função:** dar um rosto à busca antes do boss. Revelação desta visita: Nina perdeu a rabiola de Carcará adiante no parque. Ela pede ajuda numa área segura; a causa ligada ao cerol não é explicada nesta primeira conversa. Pista posterior: um vestígio a inspecionar quando a investigação estiver aberta. Não colocar a rabiola recuperável neste mapa: ela continua no pátio de Lacertubo, nas Veredas.

**Fluxo:** entrada baixa junto à placa → recuo de Nina e descanso → bifurcação. A trilha principal, larga e segura, segue pela borda sul até a subida para a Clareira. Um laço interior contorna o bosque e reencontra a saída. Um ramal sobe ao coreto num patamar de nível 1 e oferece um baú; outro baú recompensa o laço baixo. Mato alto somente em bolsões opcionais, nunca na conversa, descanso, rampas ou saídas. Ida e volta sem salto; nada de portão trancado artificial nesta área introdutória.

**Marco:** coreto no patamar do jardim, visível desde a área baixa. Secundários: placa da entrada e árvore florida junto ao descanso. Não adicionar três monumentos concorrentes. No Jardim urbano-natural, piso calmo e massas vegetais guiam; as áreas seguintes aprofundam riacho, pontes e canos.

**Relevo:** 40×32 células, isométrico 64×32; dois níveis (0 e 1). Patamar u3–16 / v3–12. Rampa larga v− em u9–11 / v13; pé v14, chegada v12. Todos os objetos do patamar apoiados no mesmo andar. Faces derivadas da camada altura; nenhum enfeite pode ocultar junta. Sem água ou ponte nesta área; não introduzir água apenas para demonstrar um kit.

| Evento / peça | Célula (u,v) | Destino ou função |
|---|---|---|
| Entrada existente, ID 36 | 4,27 | Chegada da Rua; preservar identidade do evento |
| Saída existente, ID 37 | 4,29 | `quintal` |
| Saída existente, ID 38 | 33,5 | `park-clearing` |
| Assis, ID 39 | 5,23 | Guia existente de encontros; não substituir por Nina |
| Descansos, IDs 40/41 | 8,24 / 29,8 | Funções existentes; solo seguro |
| Mapa, ID 42 | 3,24 | Interação existente; minimapa não revela todos os pontos |
| Nina, ID 43 | 9,23 | Proposta de fala: “Meu Carcará ficou lá dentro… Eu voltei sem a rabiola dele.” |
| Vestígio, ID 44 | 19,23 | Registro de proposta; revelar causa só depois do resgate, sem item novo obrigatório |
| Baú do coreto, ID 45 | 14,5 | Material de preparação, conteúdo/quantidade pendentes; sem crédito de recompensa pela planta |
| Baú do laço baixo, ID 46 | 26,28 | Recompensa opcional; conteúdo/quantidade pendentes |

Os objetos antigos IDs 1–42 são preservados e redistribuídos com suas pegadas. Não apagar Assis, descanso ou mapa para abrir espaço ao novo roteiro. Os IDs 43–46 são novos; `missao`/`fase`/`libera_apos` são metadados propostos que exigem suporte do integrador.

**Direção de arte para a etapa seguinte:** mangá 2D, contorno azul-escuro, planos de cor e uma sombra alto-esquerda; papel, varetas, nós e bandeirolas pontuais. Reutilizar coreto, bancos, postes e árvores da família parque; consultar os kits da branch de história antes de importar peças. Não usar rascunho vetorial como arte final. Exportar referência/legendas do Mapa Studio e conferir rampas 3× antes de conceito. Uma captura de planta não aprova o kit.

**Conferência e integração:** ver `art/overworld/revisao/jardim-das-pipas/RELATORIO.md`. Importar somente esta área; não reescrever kits de outros biomas. Não mover coordenadas de saves reais automaticamente. A proposta de Nina e baús aparece como dados de mapa; não significa missão ou recompensas já funcionais na campanha. Precisa conectar as novas fases ao estado existente e remapear posições antigas antes de substituir a área oficial.
