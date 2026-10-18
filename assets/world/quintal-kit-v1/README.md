# Kit do quintal v1

39 peças: 26 posições do kit compartilhado, oito peças de prédios/móveis e cinco variantes adicionais de muro. Os três recortes antigos de alvenaria foram substituídos no kit do quintal. Folha `buildings-v1.png`: varanda sem telhado, telhado separado, portão aberto e banca de linhas. Folha `furniture-v1.png`: mesa de criação, expositor de carretéis, plataforma de invocação e mural com banco.

Folha `walls-v2.png`: quatro retas e quatro quinas provenientes de uma única moldura conectada, gerada com image_gen. Não usa os recortes dos pequenos muros ilustrados do Morro. As peças são desenhadas na escala fixa de 3/16; finais curtos recortam a fonte, preservando o tamanho das pedras. A folha original permanece intacta. Prompt e auditoria de alpha em `art/world-quintal-modular-v1/`. O kit do Morro original permanece preservado.

PNGs RGBA originais, sem alteração de pixels. Recortes medidos pelo alpha com respiro adicional; as divisões das folhas não devem ser presumidas por grade uniforme. `manifest.json` reúne o atlas do quintal com o kit compartilhado, sem duplicar os PNGs compartilhados.

Referência de identidade: quintal ilustrado anterior. Direção de renderização: kit modular existente. Prompts em `art/world-quintal-modular-v1/prompts.json`. As partes novas preservam papel, pipa, telhas, madeira, cor creme e portas azul-petróleo. O jogo carrega as folhas como arquivos com hash de conteúdo, e Pages recebe cópias no build.
