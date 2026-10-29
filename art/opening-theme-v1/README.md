# O Vento Nos Chamou · propostas para o jogo

Duas propostas de arranjo instrumental geradas no ACE-Step 1.5 Turbo do ComfyUI local. O MP3 fornecido pelo usuário foi decodificado, recortado e usado como latent de entrada por VAEEncodeAudio; não foi apenas citado no prompt. Nenhuma API paga ou download de modelo. Workflows API, seeds, histórico e parâmetros preservados nesta pasta.

Abrir `ouvir.html` para comparar: **01 — menu**, intenção de flauta/celesta e dinâmica mais suave; **02 — aventura**, intenção de clarinete/metais leves com mais movimento. Cada geração tem 87,24 s. Essas descrições são direção de arranjo, não inventário certificado por escuta.

A análise espectral/autocorrelação sugeriu Ré maior e pulso de 88 BPM; pulso pode corresponder a metade do andamento percebido. Não é transcrição da melodia. O condicionamento por áudio tenta preservar contorno e harmonia, mas não garante execução nota por nota. As duas receberam instruções instrumentais; resíduos de voz e semelhança real ainda precisam de escuta. A análise Librosa inicialmente tentada não concluiu e foi cancelada; apenas os resultados de SciPy de `reference-analysis.json` foram usados.

Derivados MP3 para avaliação e Ogg Vorbis estéreo 48 kHz para o jogo. Normalização em duas passagens com alvo -22 LUFS e -2 dBTP, fades de extremidade de 12/25 ms para reduzir cliques. São alvos de processamento, não uma medição da mistura final. Repetição habilitada no Godot; emenda musical ainda exige escuta e eventual edição por compasso. FLACs originais intactos.

Integração provisória: 01 no título, menu e seleção de jornada, mantendo a reprodução ao trocar entre essas telas; 02 no prólogo após o filme da TV, em volume mais baixo sob os diálogos. O filme e seu áudio não foram substituídos. A música sai ao entrar nas áreas de campanha. Bus Music separado, slider Música em Configurações → Áudio, fades entre contextos e pausa/perda de foco acompanhadas pelo diretor. O campo novo de preferências preserva os demais volumes e saves.

Reproduzir: `tools/create-opening-theme.py prepare`, `submit`, `collect`, `package`. `submit` enfileira duas gerações e envia somente o recorte ao ComfyUI configurado. O arquivo original continua no local fornecido pelo usuário. Rodar novamente gera novos jobs e pode atualizar estas propostas; não executar como parte de um build normal.

Verificado: decodificação completa dos FLACs, medição de nível, conversão de ambos os derivados e importação dos dois Oggs. Revisão auditiva, playthrough, exportação e publicação não realizados.
