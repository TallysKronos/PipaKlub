# Cachoeiras de Kronasta

Arte gerada para o mapa top-down, processada em pixel art com paleta de 24 cores por quadro e transparência binária. Quatro quadros de 48 × 96 formam o atlas de 192 × 96. O runtime recorta boca, fluxo e espuma, repetindo módulos sem esticar a arte verticalmente.

## Uso

Atualize o Studio e abra **Cachoeiras**, no painel direito ou na biblioteca. Escolha fio de água (32 px), queda dupla (64 px) ou cortina ampla (96 px). Pinte água na origem e no poço inferior; clique na face sul do barranco entre as águas. A altura é calculada pelo desnível real. Use V para selecionar, Del para remover e Ctrl Z para desfazer.

**Abrir cenário de cachoeiras** mostra as três larguras com um poço rebaixado: a margem fica na cota 2, a água na cota 0 e as nascentes na cota 5. Ctrl Z restaura a composição anterior. O exemplo não substitui o mapa sem esse comando explícito.

## Integração

A boca avança de 12 a 17 pixels sobre a água superior, com alcance irregular, laterais suavizadas e textura comprimida no plano horizontal. A dobra na borda usa o interior da arte gerada; a antiga faixa escura horizontal não é desenhada. O encaixe acompanha o contorno de cada coluna, inclusive em saídas curvas. Captura ampliada: `documentation/plant-lab-v1/captures/waterfall-curved-mouth.png`.

- Cada cachoeira é um objeto independente na camada Objetos e sobrevive a JSON, salvar/reabrir e exportar Godot.
- As quedas acompanham a geometria atual. Sem água ou desnível válidos, deixam de aparecer, sem alterar os pisos.
- O fluxo é recortado pelas faces visíveis; boca e espuma só aparecem em água com a altura correspondente. Terreno caminhável e margens à frente não recebem esses pixels.
- Animação de quatro fases, 120 ms por fase. O cache reutiliza os quadros durante a edição.
- `godot-template/waterfalls.gd` reproduz o mesmo recorte no Godot; as quatro fases foram comparadas pixel a pixel com o Studio.
- Nesta versão as quedas são voltadas para o sul, como as faces visíveis dos barrancos do editor.

## Fontes e reprodução

[Prancha original](sources/waterfalls.png), [prompt](sources/prompt.txt), [atlas](atlas.png) e [prévia ampliada](preview.png).

Execute `python tools/plant-lab/build-waterfall-kit.py` e depois `node tools/plant-lab/build-waterfall-previews.mjs` para reproduzir os recortes e miniaturas.

Verificações: `waterfalls.test.mjs`, `waterfalls-ui-check.mjs` e `godot-preview/check_waterfalls.gd`. Capturas em `documentation/plant-lab-v1/captures/waterfalls-*.png`.
