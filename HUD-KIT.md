# HUD modular

O kit usa **3-slice** nos botões e faixas, e **9-slice** nos painéis. Os recortes são regiões independentes do atlas PNG original: não há recompressão, imagens duplicadas ou dependência de um serviço de imagens.

- Cantos e pontas têm dimensões em pixels, independentemente da largura do componente.
- Bordas retas acompanham apenas o eixo necessário. O preenchimento central pode crescer nos dois eixos.
- Os enfeites pendurados do painel ficam na região superior fixa, fora da borda vertical expansível.
- Botões têm quatro estados com os mesmos cortes. O seletor de lado usa pontas compactas, sem comprimir as folhas ornamentais do botão maior.
- Medalhões diagonais, como o relógio, preservam a proporção original em vez de serem repartidos como retângulos.
- O conteúdo e a área clicável continuam separados da decoração.

## Reutilização

As coordenadas, o modo e a escala ficam em [manifest.json](assets/ui/hud-papel-bambu-v1/manifest.json). O gerador [hud-assets.mjs](scripts/hud-assets.mjs) produz o CSS dos recortes. A montagem está em [hud-skin.js](src/hud-skin.js), compartilhada pelo jogo e pelo demonstrador.

```js
// container: position:relative; artLayer: position:absolute; inset:0;
// O conteúdo fica em outro elemento, acima da decoração.
artLayer.className = 'hud-art';
artLayer.setAttribute('aria-hidden', 'true');
mountHudSkin(artLayer, 'ranking', ART_CONFIG.hud);
```

Os componentes devem respeitar um tamanho mínimo: a área deve ser maior que a soma das pontas/cantos, mais o espaço necessário para o conteúdo. Na densidade padrão, o painel tem cantos de 45 px na horizontal, região superior de 90 px e inferior de 20,7 px. A região superior inclui os penduricalhos, preservando suas proporções. O jogo usa uma densidade menor para o placar horizontal do celular.

Botões principais usam altura de 56 px e largura recomendada a partir de 120 px. A densidade pode mudar junto com uma altura explicitamente escolhida, mas nunca em função da largura. Faixas `nameplate` usam 88 px de altura; o painel aceita alturas diferentes. A variante compacta usa 76 × 44 px no seletor de lado.

## Demonstração e testes

- `/hud-kit`: compara botões e faixas em diferentes larguras e permite variar largura e altura de um painel. O botão de verificação mede os cantos reais do DOM em 24 combinações.
- `/hud-audit`: matriz da arena real, cobrindo 319 cenários responsivos e estados de jogo.
- `npm test`: inclui cobertura dos recortes, preservação de conteúdo e eventos ao reaplicar skins e integração nos dois builds.
- `npm run validate`: valida o artefato do servidor.

Para novos desenhos, marque cortes em trechos retos e sem ornamentos. Não coloque folhas, nós ou pingentes na região expansível.
