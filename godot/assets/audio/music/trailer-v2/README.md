# Áudio de apoio ao trailer v2

`trailer-v2.ogg` tem 140 segundos, estéreo, 48 kHz. É uma **edição da gravação
existente `opening-theme-v1/vento-aventura.ogg`**, não uma composição inédita.
Os cortes e acentos estão em `marcos.json`. A introdução é a mixagem existente
atenuada, sem alegação de isolamento de um único instrumento.

A música fica em silêncio entre 2:02 e 2:12 para deixar o rugido sozinho. O rugido
é um arquivo separado: `../../sfx-v1/creature/eremor_rugido_01.wav` (relativo à
pasta `music` não; usar o caminho de recurso abaixo).

Recurso do efeito: `res://assets/audio/sfx-v1/creature/eremor_rugido_01.wav`.
É síntese procedural determinística de harmônicos vocais, respiração filtrada e
ecos, com 2,9 segundos, estéreo a 48 kHz. Não utiliza gravação de voz de uma pessoa
ou áudio extraído de outro jogo. Sugestão de entrada: 2:03, depois de um segundo
de silêncio. O vídeo público mostra apenas a silhueta, sem nome.

Regeneração: `python tools/trailer/preparar_audio_v2.py`. O WAV de trabalho fica
em `tmp/trailer-v2`, fora da publicação. `validacao.json` mede duração, picos e
ausência de clipping digital; não substitui escuta humana. Ouvir na página de
entrega antes de fechar a mixagem do vídeo. Não há medição LUFS/true-peak ou
aprovação auditiva humana registrada nesta entrega.
