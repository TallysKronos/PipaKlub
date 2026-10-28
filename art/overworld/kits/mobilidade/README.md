# Soulmonsters — veículos e mobilidade
Biblioteca de 32 sprites estáticos em uma vista isométrica frontal (frente para baixo/esquerda): 8 carros de referência brasileira, 8 jipes/utilitários, 8 versões próprias Soulmonsters e 8 objetos de mobilidade/rua.

## Arquivos
- `pecas/`: PNGs RGBA normalizados para a grade 64×32.
- `fontes/geradas/`: fontes originais em alta resolução.
- `fontes/geometria/`: guias de volume/câmera, não arte final.
- `fontes/geracao.json`: ferramenta, prompts e referências.
- `kit.json`: dimensões, bases e pivôs propostos por peça.
- `mobilidade.isostudio.json`: biblioteca importável no Iso Studio.
- Runtime em `godot/assets/overworld/kits/mobilidade/`; cenas em `godot/scenes/overworld/pieces/mobilidade/`.

## Direção e uso
Contorno azul-marinho, cel shading limpo, luz superior esquerda, vidros azuis, cores quentes e materiais legíveis em escala pequena. Os modelos de referência são interpretações gráficas, sem representação de afiliação com fabricantes. As versões Soulmonsters usam papel, varetas, carretéis e ferramentas presos à carroceria.

Imagens produzidas com image_gen.imagegen a partir de briefs próprios e referências visuais do projeto. A preparação posterior só limpa alpha tênue, recorta e redimensiona uniformemente; não redesenha a arte nem deforma proporções.

Uma vista por peça, sem animação de rodas, direção, estados de dano ou interiores. Veículos destinados inicialmente a cenário estacionado. Bases e pivôs são propostas para composição e precisam de ajuste/validação no mapa de destino. As cenas oferecem o contrato genérico de props; não foi validada navegação em torno desses veículos.

Não foram inseridos automaticamente na campanha. Catálogo e capturas de revisão ficam em `documentation/overworld/mobilidade-v1/`. Aprovação artística final pendente do usuário.

