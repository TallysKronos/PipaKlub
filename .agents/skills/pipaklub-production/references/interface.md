# Interface na engine atual

Leia `HUD-KIT.md`, `UI-KIT-AUDIT.md` e as seções de UI do `MANUAL-DE-ASSETS.md` conforme a alteração. A HUD ilustrada é parte da identidade; preservar o desenho e corrigir sua montagem é diferente de substituir o kit.

## Integração

- Reutilize `src/hud-skin.js`, `src/hud-skin.css`, o manifesto em `assets/ui/hud-papel-bambu-v1/manifest.json` e os componentes do kit atual. Pontas/cantos fixos; apenas o centro e bordas apropriadas crescem. Texto e alvo de clique permanecem no DOM, separados da decoração.
- Procure o controlador atual em `src/menu-ui.js`, `src/detail-pages.js`, `src/switch-nav.js`, `src/switch-ui-client.js`, `src/pilot-ui-client.js` e no módulo da tela. Preserve seleção, foco e navegação de retorno. Não crie uma segunda pilha de telas concorrente nem refatore todos os menus para corrigir um botão.
- CSS Grid/Flex, limites de conteúdo e safe areas resolvem o layout. Coordenadas de recortes do atlas e posicionamento dentro do Canvas continuam válidos; a recomendação externa contra posições absolutas não exige removê-los.
- No estado atual, leituras de snapshots e `requestAnimationFrame` fazem parte da integração. Evite escrita DOM redundante, mas não converta todo o HUD para eventos sem medir custo e definir o contrato.

## Auditoria proporcional à mudança

Exercite texto curto/longo, listas vazias/cheias, carregamento/erro e retorno da tela. Verifique foco inicial, Tab, Escape/voltar, restauração do foco e ausência de comandos de batalha atravessando overlays. Cursor do mouse, toque e foco devem coexistir.

Use `/hud-kit` para recortes; `/hud-audit` para arena; `/menu-audit` para telas. Confirme as rotas disponíveis no servidor atual. Proponha uma matriz representativa (por exemplo 390×844, 844×390, 1280×720 e 1920×1080), registre os viewports efetivamente obtidos e diferencie emulação de aparelho real. Não declare teste de controle físico com base apenas em eventos simulados.

Escolha os testes relevantes, como `hud-skin.test.mjs`, `ui-kit.test.mjs`, `pilot-ui.test.mjs` e `switch-nav.test.mjs`. Se a alteração alcançar ambos os destinos web, execute `node build.mjs`, `node build-pages.mjs` e as verificações apropriadas. Não edite apenas os arquivos gerados em `docs/` ou `worker/`.

Registre screenshot do resultado no navegador quando houver alteração visual. Não atribua aprovação de legibilidade ou de geometria a um teste que só inspeciona strings/código.
