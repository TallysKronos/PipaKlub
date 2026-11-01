# Riacho contínuo e água animada existente

A revisão v4 substitui a água provisória da v3 pela textura `rio-claro` e pelo shader `water_surface.gdshader` da biblioteca animada já existente no estudo do projeto. Fonte fixada em `f3df6373316305ff0c9dec449d1229f2cd0c4526`; arquivos e escopo registrados em `manga-v3/AGUA-ORIGEM.json`. O shader de origem foi importado sem alterações. A máscara opaca é local, pois o recorte do canal e as margens são derivados das células reais, mantendo a borda parada durante o movimento da água.

No mapa B, a vala inteira entre u25–38/v25–33 é água ou ponte. Não existe mais o corredor seco lateral. As duas pontes têm apoio em terra em ambas as cabeceiras e agora usam desenhos nativos de 3×11 células, 480×276 px, com mais tábuas e postes; a ponte curta não foi esticada. O rastro da missão saiu do leito para a margem norte. Vegetação decorativa foi realocada pelo mesmo critério de apoio em chão válido.

O acesso alto alternativo continua disponível mesmo bloqueando ambas as pontes. O auditor regional verificou acesso e retorno dos itens e interações. O teste de superfícies passou em 532 verificações, incluindo a ausência de piso seco na vala, água não caminhável e a passagem pelas duas cabeceiras de cada ponte.

Capturas reais com tempos fixos 0 s, 1 s e 4 s confirmaram 62.502 pixels alterados entre 0–1 s e nenhum pixel divergente entre 0–4 s, com tolerância de dois níveis por canal. Isso confere o movimento e o fechamento do ciclo na cena, não apenas o parâmetro do shader. Resultado em `animacao-conferencia.json`.

As imagens e o GIF vêm da prévia independente da Godot. A integração da missão e os saves da campanha continuam fora desta revisão. Sem push.
