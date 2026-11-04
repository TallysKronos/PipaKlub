# PIP-78 · Auditoria da interface

Revisão local em 28/10/2026. A tarefa não foi fechada no Linear: aprovação artística e verificações humanas continuam pendentes.

## Evidência

- Matriz: 68 cenários × 1280×720, 1280×800, 1600×900, 1920×1080, 2560×1080 e 1920×1200 = 408 capturas.
- Zero achados P1/P2. Existe P3 de linha parcialmente visível no grupo de controles durante captura inline; o grupo tem rolagem e o foco alcança a ação. Não ocorre na paginação da Mochila.
- Depois de ajustar a faixa de fase, as 30 combinações de boss-intro/battle/battle-paused/battle-energy/morro-battle foram renderizadas novamente e substituídas na matriz consolidada.
- `mockups/revisao/pip78/auditoria.json`: medidas e achados. A galeria `index.html` filtra por resolução e abre os PNGs em tamanho original, usando os arquivos de `tmp/player-audit-2026-10-26/pip78-final`.
- `godot/assets/ui/recorte-v1/mockups/revisao/PRANCHA.png`: uma captura real de cada cenário.
- `mockups/revisao/pip78/rodadas/report.json`: três rodadas completas, 17,75/10/26,9 segundos simulados, com 42/24/60 quadros mais resultados finais. Eventos de controle injetados; captura a cada 0,5 segundo e também em entradas de perigo.
- 13 suítes base com saída 0, mais percurso com Morro: 212 verificações, zero falhas. Resumo e caminhos dos logs finais em `documentation/battle-reports/pip78-suites.json`.
- Verificações complementares: Theme 125; glyphs/ícones 227; diálogo rápido 96; título/menu 349; PIP-76 renderizada 82; PIP-77 50, sem falhas. A execução de PIP-76 usa renderizador, pois produz capturas; não é uma suíte headless.

## Correções realizadas

- Diálogo: a caixa conservava uma altura mínima calculada antes da quebra de linhas. O texto ficava centralizado abaixo da tela. Corpo alinhado ao topo e altura recomposta após a paginação; validado nas seis resoluções.
- Paleta: placas de resultado, contorno dos textos de recompensa e modulação de retratos passaram a usar os tokens compartilhados. As cores físicas de terreno/água/bambu continuam pigmentos do mundo, explicitamente catalogados no guard de tokens; não são exceções para novas cores de interface.
- Oficina bloqueada: rodapé contextual ajusta a altura aos materiais/ações, mantendo Buscar materiais visível.
- Batalha: a faixa de JÁ/rodada foi reduzida e posicionada somente quando não intercepta os retângulos de proteção das pipas ou o cruzamento. Se ambas as posições estiverem ocupadas, o aviso é omitido. Retiradas as linhas radiais que eram desenhadas por cima das criaturas.
- Dicas e metadados: LOCAL ATUAL usa 14 px; o botão de pausa tem geometria compacta própria.
- Leitura de listas com redução de movimento mantém os losangos estáticos. Limpeza da captura de tecla ao sair da página impede uma tecla futura de alterar um remapeamento abandonado.
- Auditoria: considera apenas os controles da janela modal superior quando uma confirmação cobre outra página. Continua medindo textos e botões do modal; não confunde sobreposição intencional de janela com colisão no seu conteúdo.
- Testes de interface atualizados para validar captura inline sem janela narrativa e prompts legíveis de até duas linhas. O guard de Theme rejeita fábricas paralelas; tokens e fontes continuam com guard próprio rigoroso. Não foi removida a validação de contraste, foco, limites ou sobreposição.

## Checklist da seção 9

- [x] Paleta e quatro famílias tipográficas centralizadas; cores dos materiais do mundo explicitadas separadamente.
- [x] Textos funcionais não estão embutidos em PNG, exceto o logotipo.
- [ ] Implementação exclusivamente por Label/RichTextLabel: batalha e oficina ainda usam texto vetorial nativo do Canvas para parte da HUD. Não é texto rasterizado, mas não satisfaz literalmente esse requisito técnico.
- [x] Molduras/decoração compartilhadas e bordas sem alongamento de raster; prancha disponível para conferir a dosagem artística.
- [x] Efeitos temporários limitados; três rodadas completas registradas, sem faixa de fase sobre pipas/cruzamento.
- [x] Seis resoluções sem P1/P2 na auditoria; P3 restante registrado acima.
- [x] Navegação e remapeamento por eventos de teclado/controle simulados, retorno de foco e redução de movimento verificados por testes.
- [ ] Campanha inteira exclusivamente por teclado e exclusivamente por controle: não comprovada. A oficina continua com gestos de ponteiro e voo por teclas. O percurso automatizado usa esses gestos e callbacks reais, não comprova uma campanha sem mouse.
- [ ] Transporte físico USB/Bluetooth/Steam Input e dispositivo Steam Deck: não testados. 1280×800 foi validado como resolução, não como aparelho.
- [x] Texto ampliado a 130%, nomes longos, listas vazias e recuperação de erro têm evidência nas PIP-74/75/76.
- [x] Reduzir movimento: transição por fade de 80 ms, foco sem deslocamento, título sem piscar e efeitos sem rotação/expansão nos componentes testados.
- [x] Pares semânticos de contraste calculados em `contraste.json`: mínimo de 6,15:1, acima de 4,5:1. Isso não mede todo pixel de texto sobre ilustrações; esses casos têm contorno e conferência visual na prancha.
- [x] Fontes OFL e Kenney Input Prompts CC0 registrados em LICENSES.md e arquivos locais.
- [x] Prancha, capturas com resolução no nome e galeria de rodadas disponíveis.
- [ ] Aprovação visual final do responsável, incluindo originalidade e dosagem de tinta. Nenhum parecer jurídico de originalidade é inferido de testes automatizados.

## Referências para revisão de originalidade

Fontes oficiais consultadas: [Persona 5 Royal, galeria PlayStation](https://www.playstation.com/en-us/games/persona-5-royal/) e [Splatoon 3, Nintendo](https://splatoon.nintendo.com/en/gameplay/). As mídias oficiais não foram incorporadas ao jogo. O kit usa logo Soulmonsters, pipas/rabiolas, ícones próprios, fontes licenciadas e paleta papel/ciano/sol. A aprovação comparativa de direção de arte permanece humana, com a prancha disponível.

Nenhum comentário de fechamento foi publicado no Linear; o checklist acima é o registro local para revisão. Nenhum merge, push ou publicação foi feito nesta rodada.
