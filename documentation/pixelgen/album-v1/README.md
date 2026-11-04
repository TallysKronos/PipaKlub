# Álbum de personagens e salvamento conectado

Home do Pixelgen com13personagens humanos: Kael, os8NPCs atualmente ligados ao sprite direcional e os4Cerol Hunters preparados. O catálogo é explícito em `tools/pixelgen/character-catalog.mjs`, a partir dos consumidores `kael_video_avatar.gd` e `npc_pixel_sprite.gd`; não lista rascunhos antigos como arte atual. Cerol Hunters continuam identificados como fora dos mapas. Kael tem entradas separadas para caminhada, salto e receber item.

Clique numa figurinha, selecione a ação se houver, edite pixels/camadas/paleta e aguarde “Salvo”. A pausa de500ms agrupa alterações. A gravação salva o documento `.pixelgen.json`, o PNG de produção, a cópiaPNG usada pelo Godot e o `.aseprite` correspondente. Histórico dos arquivos anteriores em `.local/pixelgen-history/<asset>/`; manifestos indicam quais arquivos cada revisão preserva. O processamento e as gravações são locais, pelo servidor Pixelgen em127.0.0.1.

Camadas, pincel, borracha, paleta, seleção e desfazer mantêm o vínculo. Bancada livre e abertura de outro arquivo encerram o vínculo após salvar. A grade, a ordem e os nomes dos quadros são preservados nas entradas conectadas; temporização e novas ações continuam no fluxo de cópia/exportação porque os controladores do jogo mantêm seus contratos de movimento.

O serviço valida o documento e a revisão antes de escrever, limita o corpoHTTP, aceita somente IDs do catálogo e recusa origem externa/host não local. Gravações são serializadas por asset, preparadas em arquivos temporários e acompanhadas de backup/rollback. Conflitos entre abas e erros mantêm a edição pendente e o indicador de erro; não são tratados como sucesso. O salvamento do navegador continua como recuperação adicional.

## Godot local

O autoload `PixelgenSprites` cria ImageTextures para os sprites atuais no projeto local. A cada segundo verifica o conteúdo dos arquivos que já foram carregados e atualiza as mesmas texturas; NPCs e Kael mantêm suas referências. Builds exportados usam os recursos importados e exigem novo build para distribuir mudanças. Jogos já abertos antes de receber esse autoload precisam ser reiniciados uma vez.

## Evidências

- TestesNode do serviço: exportação das camadas para pixels reais, documentoAseprite, backup do original, conflito de revisão e estrutura incompatível rejeitada.
- Testes do autosave: mudança durante requisição em voo, flush antes de navegação e recuperação após falha.
- Rotas: catálogo, projeto, previewPNG e rejeição de pedidos de escrita indevidos.
- Verificação DOM existente do editor preservada; busca e abertura de Nina verificadas em navegador real.
- Teste reversível no navegador: deslocamento de1px em Nina atualizou `godot/assets/npc-ds/nina.png`; desfazer restaurou os pixels. Os quatro arquivos originais foram restaurados byte a byte ao terminar a auditoria.
- Teste gráfico nativo `godot/tests/pixelgen_reload_test.gd`: PNG muda de vermelho para azul e uma ImageTexture existente passa a retornar os pixels novos sem reiniciar. Executado com OpenGL naRTX5070; o renderizador dummy headless não serve para leituraGPU e é explicitamente ignorado nesse teste.
- `home.png`: captura do álbum no navegador. Não houve publicação, commit ou alteração intencional da arte do elenco.
