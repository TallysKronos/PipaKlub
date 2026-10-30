# Tyler e Saber — Um fio de coragem

Curta de anime em produção, duração editorial **80 segundos**, dez planos de oito segundos. Pedido: Tyler e Saber entram na floresta, uma garota pede ajuda, os dois enfrentam Lacertubo e vencem.

## Continuidade

Tyler V3 e Saber V2 são as identidades de referência aprovadas. Lacertubo usa o retrato do rig V2. A garota do curta, chamada Lia apenas nos arquivos de produção, é uma nova proposta: pele morena, cabelo cacheado curto, presilha de folha amarela, poncho verde-azulado, shorts mostarda e bolsa coral. Não há revelação da origem secreta do Tyler.

A menina precisa atravessar a ponte bloqueada pelo Lacertubo. Tyler e Saber ajudam, desviam do primeiro ataque, contra-atacam, preparam o Laço de Cerejeira e vencem. No final a ponte está livre. O golpe e a personagem nova são elementos deste estudo, não alterações automáticas do cânone ou gameplay.

## Arquivos e ferramentas

- `keyframes/`: dez imagens novas do imagegen integrado, referências de composição e identidade; não contam como duração do filme.
- `image-prompts.json`: prompts das dez imagens.
- `film-plan.json`: roteiro, intervalos e falas/legendas pretendidas.
- `workflows/`: dez grafos API reais do H3 local. Todos passaram na validação local antes de serem enfileirados, sem nós pagos.
- `jobs.json`: IDs reais, estado e saídas da fila; atualizado pelo coletor.
- `video-original/`: clipes AV realmente gerados, preservados sem edição.
- `edit/`: normalização editorial de cada plano para 192 quadros/8s.
- Entrega: `documentation/tyler-saber-forest-film-v1/tyler-e-saber-um-fio-de-coragem.mp4` quando a montagem terminar.

H3 instalado `minimax_h3_ref2va_pruned_int8_convrot`, VAE de vídeo int8, VAE de áudio fp32, codificador Qwen3VL32B nvfp4. Fonte 864×480, 24fps, 20 passos, 192 quadros por plano, seed2810202680..89. Exportação720p redimensionada proporcionalmente, não geração HD nativa. RTX5070 de12GB: os três primeiros planos levaram cerca de9–10min cada.

Guia de imagem no quadro0 de cada plano; no plano9 há guia final de pós-vitória para tornar a derrota explícita. As pranchas de identidade não são apresentadas como imagens dentro do vídeo. Há cortes cinematográficos entre planos; não se afirma que80segundos foram gerados num único latente contínuo.

## Montagem

`tools/create-tyler-saber-film.py` prepara grafos/roteiro. **Não enfileira** e não atualiza ComfyUI/modelos. `tools/collect-tyler-saber-film.py` lê somente os IDs deste curta, recolhe resultados locais e registra erros. Não interrompe outros trabalhos. `tools/assemble-tyler-saber-film.py` exige dez planos concluídos antes de produzir a entrega; não completa duração com stills ou loops. O modo `--prepare-only` escreve apenas as legendas.

O filme usa os sons/falas gerados pelo H3 e a trilha já existente do projeto (`02-parque-v2`, `03-batalha-v2`), com redução da música durante o áudio dos planos. Legendas PT-BR seguem o roteiro, não são transcrição verbatim certificada por ASR. Pronúncia, sincronismo labial e voz podem variar entre gerações; exigem avaliação audiovisual.

A montagem final verificará80segundos e1920quadros por decodificação completa. As pranchas de quadros permitem conferir identidades, espaço e desenlace, mas não substituem assistir ao vídeo com áudio.

Não altera a campanha, não publica e não envia ao Git. Este diretório preserva versões e material de produção.
