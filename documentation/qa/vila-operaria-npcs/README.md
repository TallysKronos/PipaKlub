# Revisão nativa do elenco da Vila Operária

Ferramenta reproduzível: `godot --path godot --script res://tools/vila_operaria_npc_capture.gd`. Teste visual isolado no renderer real de `kronasta-industrial-a`, sem editar mapas ou habilitar campanha. Cinco eventos apenas em memória, sprites passando pelo mesmo consumidor storySpritePath usado pelos NPCs existentes.

Resultado executado em Godot4.7.2/OpenGL: cinco texturas importadas de112px, renderização nativa84px, cinco posições caminháveis com rotas calculadas desde entrada, seis capturas1280x720. Capturas individuais usam zoom2 e ocultam outros NPCs; grupo zoom1.3. Revisão visual realizada no grupo e cinco imagens individuais. Primeira tentativa rejeitada por posições próximas demais de bordas/oclusão; seleção ampliada para vizinhança3x3 nivelada e espaçamento projetado mínimo125px. A rota é calculada, não percorrida pelo controlador.

Observado: silhuetas distinguíveis, transparência sem halo evidente, apoio dos pés e ordenação coerentes nos pontos finais. Bruno e Vasken são mais arredondados que Rivka/Odrik; Teyra mantém massa na gola. Detalhes pequenos ficam suaves no zoom2 por origem112px; isso não é arte nativa de alta resolução.

Limites: NPCs não integrados ao fluxo da campanha; posições são de galeria, não encontros definitivos. Sem diálogo, duelo, defesa, recompensas, áreaD ou boss. Nenhuma animação/captura de movimento. Campanha completa, controle humano, export Steam e outras câmeras não verificados. Os mapas industriais ainda são prévias de história.

Importação retornou0 com aviso preexistente de safe-save do editor; proteções não foram alteradas. Captura nativa final retornou0 sem erros. UIDs alheios criados pelo import foram removidos; conserva-se UID da nova ferramenta. Mapas e kit.json não foram modificados.
