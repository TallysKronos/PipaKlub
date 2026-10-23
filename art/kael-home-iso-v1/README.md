# Casa de Kael — sala e cozinha

Kit ilustrado do piso inferior, no mesmo acabamento do quarto v4. Madeira mel com veios, tecido teal, creme, detalhes de latão e luz superior esquerda. As guias vetoriais são referências técnicas e não aparecem como arte final.

## Entrega

- `sources/`: oito imagens originais da ferramenta integrada **image_gen**: sofá, mesas de centro/refeições, banco, cozinha, escada, porta e casca.
- `guides/`: caixas e formas editáveis SVG, guias PNG em escala nativa e 4×.
- `prompts.json`: texto comum e diretiva completa de cada pedido, com as referências usadas.
- `sala-kael.isostudio.json`: projeto editável do Iso Studio com imagens incorporadas.
- `conferencia.json`: conferência de dez peças. A revisão atual registra falhas de perspectiva das fontes; não equivale a aprovação visual.
- Runtime: `assets/world/kael-home-iso-v1/manifest.json`, dez peças e a casca, todos com alpha real.

Tapete e janela vêm das fontes originais do quarto v4, sem reutilizar sua exportação deformada. Os dois bancos compartilham a mesma fonte; são peças independentes na montagem e na colisão.

## Grade e produção

Sala de 12×9 células, paredes de cinco unidades. Piso 64×32, altura de célula 32 px; 96 unidades lógicas correspondem a uma célula de arte, igual ao quarto. O preset está em `src/home-layout.js` e abastece o mapa explorável e o piso inferior da abertura.

Reproduzir as guias: `node scripts/build-home-guides.mjs`. Exportar as fontes para o jogo e para o Studio: `node scripts/prepare-home-art.mjs`, depois `node build.mjs` e `node build-pages.mjs`. Sharp pode vir do pacote local ou do runtime fornecido ao ambiente.

A revisão do usuário rejeitou as exportações anteriores: o registro por coluna cortava visualmente almofadas, ondulava mesas e deformava degraus, inclusive no modo que ajustava somente a base. O resultado anterior de 10/10 era geométrico e não comprovava integridade da ilustração.

A exportação atual recorta apenas margens transparentes, aplica uma única escala proporcional e acrescenta espaço transparente para manter as dimensões nativas do contrato. Preserva o antialiasing e não usa guias como máscara, registro por coluna ou esticamento de proporção. As fontes originais permanecem disponíveis. O renderer continua desenhando cada PNG em tamanho nativo.

Estado: integrado localmente, em revisão geométrica. As fontes ainda apresentam ângulos diferentes de 2:1; `prepare-home-art.mjs` exporta e retorna código 1 ao registrar esses desvios. Corrigir a perspectiva na fonte antes de aprovar geometria; não deformar a ilustração para obter aprovação. Esta correção abrange a sala; o exportador separado do quarto ainda precisa da mesma revisão.

A conferência geométrica não aprova automaticamente estilo, luz ou comportamento no jogo; a revisão visual e de navegação é registrada em `documentation/sala-kael-isometrica.md`.
