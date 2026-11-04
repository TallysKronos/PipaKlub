# Piso de terra mangÃ¡ â€” revisÃ£o 3

Refinamento isolado do piloto, 29/10/2026. Acrescenta uma pintura original gerada com imagegen: grupos esparsos de pedrinhas angulares, lascas e marcas curtas em terra ocre. O chÃ£o continua com Ã¡reas calmas.

A pintura Ã© compartilhada entre cÃ©lulas e patamares, em coordenadas lÃ³gicas do terreno, com perÃ­odo espelhado de 512 pixels e mistura de 82%. NÃ£o reinicia por losango. A fonte reÃºne vÃ¡rios motivos diferentes em vez de distribuir uma pedra idÃªntica em cada tile. O espelhamento mantÃ©m a mesma amostra na fronteira da repetiÃ§Ã£o. As versÃµes anteriores das capturas foram preservadas.

[ComparaÃ§Ã£o visual com o piso liso aprovado](index.html). OpÃ§Ãµes de praÃ§a, rampa e acessos das pontes na mesma cÃ¢mera. DiagnÃ³stico de cores chapadas desativa a pintura para inspecionar a geometria.

Fonte: `godot/assets/overworld/terrain-pilot-v3/terra-pedrinhas-manga.png`. PNG RGB 1254Ã—1254, opaco, sem colisÃ£o; filtragem linear. Origem e brief em `asset-source.json`. Sem recorte, quantizaÃ§Ã£o ou pintura posterior Ã  geraÃ§Ã£o.

Uso restrito Ã  prÃ©via `godot/tools/terrain_pilot_view.gd`; campanha e mapas fonte permanecem inalterados. O capturador usa `res://tools/terrain_pilot_capture.gd`; com `-- --live`, F6 alterna original/revisÃ£o atual sem salvar campanha. A comparaÃ§Ã£o HTML permite avaliar especificamente revisÃ£o 2/revisÃ£o 3.
