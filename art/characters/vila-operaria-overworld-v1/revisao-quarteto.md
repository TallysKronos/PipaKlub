# Quarteto de overworld

Fontes individuais geradas por imagegen nativo com Bruno como escala/estilo e pranchas próprias como identidade. Empacotadas junto a Bruno pelo contrato estático existente: altura de conteúdo112, PNG RGBA, um frame sudeste. `qa.json` registra dimensões/alpha/recorte; `preview-112.png` mostra os cinco em escala real.

Verificação executada: cinco fontes com alpha mínimo0/máximo255, conteúdo sem encostar nas bordas da fonte, saídas com altura112. Prévia completa inspecionada: Vasken cabelo/mangas, Rivka vela/avental, Odrik loop/manga única e Teyra gola/barba continuam distinguíveis. Vasken inicial falhou por alpha máximo254 e névoa colorida, foi preservado em `vasken-rejected-halo.png`; edição dirigida produziu recorte aceito pelo empacotador e sem halo evidente na prévia.

Limites: proporções variam (Rivka/Odrik mais alongados), detalhes finos de rosto/carretel perdem leitura a112. Não são rigs nem animações. Sem importação/captura Godot nesta etapa e sem ligação a NPCs de mapa. Transparência verificada numericamente e visualmente sobre fundo escuro, não em todos os fundos. Comparação de lados anatômicos quadro a quadro não executada, apenas sprites estáticos. Próxima etapa é validar no mapa real e ajustar escala/pivô se necessário.
