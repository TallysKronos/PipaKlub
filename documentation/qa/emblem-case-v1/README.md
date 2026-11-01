# Porta-emblemas · estojo de bairro

31/10/2026. Implementação local, ainda sem push.

O porta-emblemas ganhou uma tela própria, aberta sobre o cenário pausado: estojo azul com fechos laranja, dobradiça, ilustrações de pipa na lombada, bordas de tinta e retícula discreta nas costuras. A grade mantém 12 posições em quatro colunas e três linhas. Os espaços pendentes têm cadeados; seleção e foco usam borda dourada.

À direita, o item selecionado é ampliado e apresenta nome, bairro, chefe, descrição e data quando esses dados existem na conquista salva. Espaços bloqueados não revelam nomes de chefes ou bairros futuros. Um contador mostra o total de conquistas.

## Acesso e comandos

- **Pausa → Porta-emblemas**, disponível após o treino/documentos.
- **Carteira de Pipeiro → Abrir porta-emblemas**.
- Mouse ou navegação por foco para escolher uma posição.
- **Tab / Shift+Tab** ou botões de ombro do controle alternam Todos, Conquistados e Pendentes. Os botões também são clicáveis.
- **Fechar / Escape / voltar do controle** restaura a tela anterior e seu foco. O cenário continua pausado até Retomar. O atalho M não atravessa o modal.

A carteira continua com os dados pessoais e o resumo anterior. A nova tela não concede emblemas nem altera a emissão de documentos, a entrega por banners ou o encerramento da demo.

## Dados

Os 12 chefes e suas artes definitivas continuam por definir. O save real testado permanece em **0/12**. Não foram criadas conquistas de campanha para os treinos ou o Lacertubo.

`Identity.award_district` aceita agora um quinto argumento opcional com `districtName`, `bossName` e `description`. Campos antigos continuam válidos. Esses dados são validados e guardados com a mesma conquista, sem mostrar IDs técnicos na interface. Nomes têm limite de 64 caracteres e a descrição, 320.

As imagens `exemplo-visual-*.png` usam **três exemplos exclusivamente visuais em uma cópia na memória** para mostrar os estados conquistado/bloqueado e os detalhes. Os nomes e os símbolos dessas imagens não definem novos personagens, bairros ou emblemas oficiais. O teste confirma que eles não chegam ao save.

## Evidência

- `emblem_case_checks.gd`: 60 verificações aprovadas: acesso por pausa/carteira, 12 posições, seleção, filtros vazios/parciais, Tab e ombro simulados, Escape, bloqueio de comandos e foco da tela abaixo, metadados, nomes longos e ausência de recompensas ao visualizar.
- Regressões: `pipeiro_identity_checks.gd` (78), `key_item_banner_checks.gd` (28) e `campaign_checks.gd` (206) aprovadas. Total: 372 verificações sem falhas.
- Capturas do renderer nativo inspecionadas em 1280×720 e 1920×1080: [save vazio](estojo-vazio-1280x720.png), [exemplo visual com três conquistas](exemplo-visual-1280x720.png).

Os testes usam saves isolados. Não houve teste com controle físico nem novo playtest humano completo.
