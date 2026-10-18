# Pipa Klub — kit Papel e Bambu v1

Pacote de fundação visual produzido a partir da análise da proposta Switch. É um catálogo independente: não muda menus do jogo nem publica uma versão em produção.

## Conteúdo

- 16 bases PNG com transparência: quatro botões, janela, cartão, duas abas, duas bases de ação, balão, cabeçalho, rodapé, recurso, campo e tooltip.
- Nove ícones pintados: seis destinos do menu e três ações de batalha.
- 48 glifos SVG: Xbox, PlayStation, teclado/mouse e toque, também reunidos em `glyphs.svg`.
- Quatro selos SVG: equipado, bloqueado, evento e crítico.
- Quatro retratos de demonstração recortados das artes existentes; não são criaturas novas.
- `manifest.json`: dimensões, coordenadas de origem, insets, escala, tamanho mínimo e hashes dos recortes.
- `skins.css`: decorações e recortes. `kit.css`: componentes reutilizáveis e estados.
- `index.html`, `catalog.css`, `catalog.js`: catálogo de inspeção, com redimensionamento, comandos, recarga e navegação por teclado.
- `sources/`: dois atlas originais selecionados e prompts completos da geração.

## Abrir o catálogo

Na raiz do repositório:

```sh
node scripts/preview-switch-kit.mjs
```

Abrir `http://127.0.0.1:5195/ui/kit-switch-v1/index.html`. O servidor local é somente de leitura e serve a pasta pública de assets. A porta pode ser alterada com `PIPA_KIT_PORT`.

No pacote ZIP, também é possível executar `node preview.mjs` dentro da pasta extraída e abrir `http://127.0.0.1:5195`. Essa versão não precisa do repositório do jogo.

## Usar um botão

Carregar `skins.css` e `kit.css`. As URLs são relativas à pasta do kit. Em um contêiner `.pk-kit`:

```html
<button type="button" class="pk-button">
  <span class="pk-skin" data-skin="button-primary" aria-hidden="true"></span>
  <span class="pk-content">Jogar</span>
</button>
```

Usar `button-secondary` para alternativa e `button-destructive` com `data-variant="destructive"` para ação destrutiva. Usar o atributo nativo `disabled`. `aria-busy="true"` mostra carregamento; o código consumidor deve impedir cliques repetidos enquanto a operação estiver em andamento.

Botões têm alvo de 64 px; a pintura interna tem 54 px. As faixas esquerda e direita medem 32 px cada, independentemente da largura total. O centro cresce horizontalmente. Os rótulos são texto real e não quebram em linhas. Defina a largura pelo contexto; não reduza a fonte para forçar um rótulo a caber.

## Painéis e estados

```html
<section class="pk-frame">
  <span class="pk-skin" data-skin="window" aria-hidden="true"></span>
  <div class="pk-content">Conteúdo da janela</div>
</section>
```

Os painéis usam o recorte nativo de nove partes do navegador (`border-image`). Os cantos usam largura fixa; a borda não depende da porcentagem da largura do painel. Esse método evita a junção de vários elementos posicionados separadamente em coordenadas fracionárias. A inspeção visual continua necessária para cada contexto.

Foco é contorno independente em `:focus-visible` ou `.pk-focus`. Ponteiro e pressionado são tratamentos de código. A opção de movimento reduzido mantém foco visível e desliga o pulso. Seleção de aba, equipamento e bloqueio não devem ser inferidos do foco.

### Abas e bases circulares

O PNG `tab-selected.png` contém um indicador central pintado e deve preservar sua proporção. Para **abas redimensionáveis**, o componente `.pk-tab[aria-selected=true]` usa a base secundária em três partes e um indicador geométrico separado. Assim o triângulo não se alarga junto com a aba.

As duas bases circulares também são peças inteiras. Use `background-size:contain`, sem esticar largura e altura de maneira independente. A moldura do retrato usa nove partes; seu rosto é uma camada separada.

## Comandos e batalha

Os comandos do catálogo são exemplos de composição, não alteram as teclas do jogo. Na integração, associe cada ação ao mapeamento real do jogador. Não reutilize uma ação de menu como ação de batalha só porque o controle usa a mesma letra: Voltar e Esquiva são ações distintas.

Os SVGs têm `viewBox="0 0 64 64"`. Usar glifos de ação em aproximadamente 28–32 px e alvos de toque maiores. Texto explicativo fica fora da imagem. Os símbolos PlayStation são vetores geométricos; as letras e teclas usam texto SVG, sem texto gerado na pintura.

O anel de recarga do exemplo é um círculo SVG com progresso configurado por `--pk-cooldown`. O valor vai de 333 (vazio) até 0 (completo). Não há spritesheet de recarga ou de foco.

## Reconstruir os recortes

O script utiliza `sharp` exclusivamente para cortes mecânicos dos atlas e dos retratos existentes. Não repinta, recolore nem modifica a transparência dos arquivos gerados.

```sh
node scripts/build-switch-kit.mjs
```

Requer o pacote Node `sharp`. Se ele estiver no runtime de trabalho, apontar `PIPA_KIT_NODE_MODULES` para o diretório `node_modules` desse runtime. Os artefatos finais já estão incluídos; não é preciso executar o script para usar o kit.

## Validação e limites

O catálogo oferece verificação de 24 combinações de dimensão para os cantos e permite conferir larguras fracionárias pelo navegador. A produção deve validar também 1280×800, 1920×1080 e celular deitado, com os textos e regras reais.

Fontes do componente herdam Nunito e Lilita One quando disponíveis no jogo; o catálogo funciona sem fontes remotas usando alternativas locais. As ilustrações são raster e não devem ser ampliadas indefinidamente; os recortes estão pensados para a escala de interface indicada no manifesto. Os glifos são vetoriais.

Este pacote cobre a fundação, os comandos e os ícones centrais da proposta. Não inclui as futuras ilustrações das seis lições, cenários inéditos ou a migração das telas do jogo.

Arte produzida com a ferramenta integrada `image_gen.imagegen`; prompts em `sources/prompts.json`. Recortes, manifesto, SVGs e catálogo montados no projeto.
