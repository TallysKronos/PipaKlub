# Bairro — revisão dos pisos

Pinturas novas de concreto, asfalto, grama e terra, compartilhadas entre células por UV em coordenadas do mundo. Guias e sarjetas seguem as bordas da planta; ralos, tampas e pequenas fissuras são decalques sem colisão. Sombras de árvores e construções são aplicadas na renderização.

A primeira grade procedural de juntas foi rejeitada pelo usuário. Ela foi removida por completo do shader. A versão atual usa placas maiores e desencontradas na própria pintura, com juntas em bege suave. `calcada.png` preserva a primeira geração; `calcada-placas.png` é a fonte atual. Prompts e origem estão em `art/overworld/kits/bairro/fontes/pisos-v2/proveniencia.json`.

As pastas `antes/` e `depois/` contêm capturas nativas. A revisão atual conferiu a praça e a casa de Kael a 1280×720; o gerador registrou também Assis, loja, detalhe de piso e visão geral. São capturas de renderização, sem percurso de campanha ou suíte de testes. A importação não registrou erro e `git diff --check` passou.

Sem alterações de navegação, campanha, inventário ou salvamento. O kit completo permanece em revisão local na PIP-84.

Referência técnica: [CanvasItem shaders — MODEL_MATRIX e coordenadas](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html). A pintura usa UV comum entre polígonos para evitar repetir a borda do tile em cada célula.
