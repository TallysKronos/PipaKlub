# Brief · Oficina das Almas (bancada) · para o Codex

**Status:** pendente · **Épico:** PIP-58 · **Entrega:** `art/oficina-das-almas/v1/` · **Dados:** [`brief.json`](brief.json) · **Consumidor:** protótipo `tools/oficina-prototipo/` (depois, a oficina do jogo)

Leia antes: `MANUAL-DE-ASSETS.md` (seções 02, 03, 05 e 06) e `.agents/skills/pipaklub-production/references/assets.md`. Mecânica e motivos em [`documentation/oficina-das-almas/REFERENCIAS.md`](../../documentation/oficina-das-almas/REFERENCIAS.md) e [`DESIGN.md`](../../documentation/oficina-das-almas/DESIGN.md). Jogue o protótipo antes (`tools/oficina-prototipo/index.html` por um servidor local): a arte atual dele é provisória e é ela que esta entrega substitui.

## A cena

Bancada do Sr. Assis vista de cima. A alma deixou uma **marca luminosa** dentro de uma **folha bruta** (papel dobrado, retalhos colados e cola velha). O jogador raspa os retalhos com **estilete** e **tesourinha** para revelar a marca sem rasgá-la, conserta os defeitos dos materiais com cinco ferramentas, monta a vela na armação, testa o voo e amarra a rabiola.

Linguagem do PipaKlub: papel vivo, dobras, varetas de bambu, nós, cola e rabiolas; cores quentes e legíveis. A marca da alma é a única coisa que brilha antes do despertar.

## 1. Pesquisa de referências (primeiro passo)

Este ambiente do Claude não acessa sites de imagem; o Codex coleta.

- Capture de 6 a 10 imagens de **Fossil Fighters** (DS e Champions; Frontier se achar): pedra no início, martelo e broca em uso, raio-X ligado, medidor azul/vermelho na tela de cima, resultado da limpeza.
- Capture de 4 a 6 imagens de **Digimon Story Lost Evolution**: tela de reparo da DigiPlate com as ferramentas, placa com rachaduras e cristais, resultado e a Árvore de Evolução.
- Salve em `art/oficina-das-almas/referencias/` (a pasta é ignorada pelo git: as imagens são de terceiros e servem só de consulta interna). Registre cada uma em `referencias/FONTES.md` (versionado), com URL, data e uma frase sobre o que ela ensina (composição, leitura do dano, cursor, retorno visual).
- Use as referências para **composição e leitura**, nunca para copiar personagens, marcas ou interfaces de terceiros (manual 03.1).

## 2. Peças da bancada

Coordenadas no espaço lógico do protótipo: bancada de **600 × 440**, entregue em **2×** (1200 × 880). A folha ocupa a área `x 120–480, y 4–436`. Os contornos estão em `brief.json`; a marca e a vela têm de coincidir com eles a ±2 px lógicos.

| ID | O quê | Formato e tamanho | Observação |
|---|---|---|---|
| `bancada-fundo` | Tampo da bancada visto de cima: madeira, grampos, retalhos, potes | PNG opaco 1200 × 880 | Centro mais limpo onde fica a folha; nada importante sob o painel lateral |
| `folha-<papel>-camada-<1..3>` | Retalhos que cobrem a marca, por papel (`seda`, `manteiga`, `encerado`) e profundidade | PNG RGBA 256 × 256, **ladrilhável** | A camada 3 é a mais grossa e escura. O encerado tem brilho de cera; o de seda é fino e translúcido |
| `rasgo-borda` | Bordas de rasgo para onde o estilete atingiu a marca | PNG RGBA, 6 variações de 48 × 48 | Fibras de papel e um leve tom avermelhado na fibra |
| `marca-rabbito-padrao` | A marca da alma do Rabbito, luminosa, no contorno `rabbito-tradicional` | PNG RGBA 720 × 864 (2× da área) | Brilho ciano suave, rosto discreto. É o que aparece quando a camada sai |
| `marca-rabbito-excepcional` | Mesma marca na aparência excepcional | PNG RGBA 720 × 864 | Diferença **física**: capuz das orelhas em outra cor e padrão (ver a referência do Carcará no PIP-58). Não basta trocar o filtro |
| `marca-rabbito-vela-leve-*` | As duas marcas no contorno `rabbito-vela-leve` | PNG RGBA 720 × 864 | Molde raro: vela mais larga |
| `vela-rabbito-*` | A vela já recortada (depois do despertar da luz): padrão e excepcional, nos dois moldes | PNG RGBA 720 × 864 | Mesma arte do rig colorido do Soulgen; é a peça que vai para a montagem |
| `armacao` | Cruz de varetas de bambu com amarrações | PNG RGBA 720 × 864 | Vareta vertical de y 92 a 372 e horizontal de x 186 a 414 (lógico) |

## 3. Ferramentas

Para cada ferramenta: **ícone** do cinto (PNG RGBA 128 × 128) e **cursor** sobre a bancada (PNG RGBA 64 × 64 com o ponto ativo marcado em `brief.json`).

`estilete`, `tesourinha`, `luz-do-molde`, `remendo` (pincel com cola), `ferro` (ferro de passar pequeno, morno), `lixa`, `pano` (úmido), `agulha` (com linha).

O estilete precisa parecer forte e arriscado; a tesourinha, delicada. O cursor não pode esconder o ponto de contato.

## 4. Defeitos do reparo

Cada defeito em dois estados, **aberto** e **consertado**, PNG RGBA 96 × 96: `rasgo` (no papel), `ruga` (no papel), `farpa` (na vareta), `mancha` (barro no papel), `embolada` (linha embolada). O estado consertado mostra o conserto (remendo, papel liso, vareta lixada, papel limpo, linha alinhada), não some.

## 5. Retorno visual

- `medidor-silhueta`: moldura 192 × 192 para a miniatura que enche de dourado (revelado) e vermelho (rasgo). Pode ser uma etiqueta de papel presa com fita.
- `lascas`: folha de 6 quadros (6 × 96 × 96) de lascas de papel saltando no golpe do estilete.
- `brilho-revelacao`: folha de 8 quadros (8 × 128 × 128) do brilho quando um trecho grande da marca aparece.
- `despertar`: folha de 12 quadros (12 × 256 × 256), a marca virando a vela e a vela ganhando cor, para fechar a etapa da rabiola.

## Pronto quando

- Arquivos com os nomes, tamanhos e alpha pedidos; relatório do `asset_report.py --require-alpha` para cada PNG RGBA.
- A marca e a vela, sobrepostas aos contornos de `brief.json`, coincidem a ±2 px lógicos (anexar a prévia com o contorno desenhado por cima).
- Prancha de revisão em fundo claro e escuro, e uma captura da bancada montada na escala de 1280 × 720.
- `referencias/FONTES.md` preenchido.
- `"status": "entregue"` em `brief.json`. A integração no protótipo e no jogo fica com o Claude.
