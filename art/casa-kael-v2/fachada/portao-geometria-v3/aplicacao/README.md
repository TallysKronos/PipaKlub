# Aplicação dos volumes aprovados

O dono autorizou a pintura e aplicação do estudo. A solução v3 agora está montada na Vila.

## Construção

Os pilares, muros e tampas usam as coordenadas do blockout em `portao-geometria-v3/medidas.json`. Cada face é projetada no Godot a partir dos mesmos vértices e participa do mapa de profundidade usado pelo Kael e pelo companheiro. A folha do portão tem moldura, barras e dobradiças, aberta para dentro. O correio é um volume preso ao pilar direito.

O reboco frontal usa creme `#F0DCC0`, faces laterais em sombra quente `#B59F8E` e tampas claras `#F7F3EE`. O piso usa cinza `#C8CDD1`, com juntas discretas `#9DA9B5`, na cota física 8 da calçada. A faixa de pedras para nas bordas do vão, sem uma face de degrau no centro. A base do piso recebe apenas o pequeno bias de desenho habitual para evitar disputa com o terreno.

A pintura principal da casa permanece raster, em escala nativa. A bicicleta foi extraída e limpa no Aseprite como prop separado, apoiado no chão fora do muro. Os antigos recortes de muro e soleira foram retirados do runtime; suas versões anteriores permanecem no histórico Git e nas fontes de arte.

Fontes editáveis

- `art/casa-kael-v2/fachada/fontes/kit-portao-v3.aseprite`, recortes da casa com os trechos substituídos por geometria removidos. Camadas antigas ficam ocultas para referência.
- `art/casa-kael-v2/fachada/fontes/bicicleta-portao-v3.aseprite`, bicicleta isolada e limpa.
- `godot/scripts/overworld/kael_house_v2.gd`, construção e acabamento dos volumes na projeção do jogo.

## Verificação e evidências

`../../integracao/qa.json` registra 39 verificações e zero falhas. A rotina confere a montagem, os filtros, a presença das faces opacas no mapa de profundidade, as duas pegadas dos pilares, as colisões, a altura compartilhada da passagem e da calçada, a travessia contínua nos dois sentidos e a entrada/saída da casa preservando HOME.

Os testes usam um slot descartável em `.local/qa`, sem abrir saves pessoais. Não houve mudança de regras da campanha ou do interior.

- `antes.png` e `depois.png`, vista aproximada antes e depois.
- `../../integracao/portao-detalhe.png`, detalhe atual.
- `../../integracao/passagem-contato.png`, seis momentos da travessia.
- `../../integracao/comparativo.png`, concept, volumes aprovados e captura do jogo.

A revisão visual independente aprovou a aplicação sem bloqueio geométrico. Confirmou as faces terminais, a diferenciação entre muro e piso, a folha ligada ao pilar, apoio da bicicleta, continuidade da passagem e oclusão durante a travessia.
