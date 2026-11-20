# Papisco — overworld 32×32

Versão solicitada pelo autor após visualizar a base do Papisco em 64×64. Conversão no Aseprite com limpeza nativa dos olhos âmbar, peito-pipa e dois pendões; as pequenas divisões da arte maior foram simplificadas. Origem: `../overworld-64-v1/pose-gerada.png`, gerada por image_gen a partir do concept próprio `../concept-v1/concept.png`, com Alvacordo v5 apenas como acabamento/proporções. Prompt preservado na pasta 64.

- `papisco-master-32.png` / `.aseprite`: pose estática.
- `papisco-32.aseprite`: fonte animada, quatro camadas editáveis.
- `papisco-32.png` / `.json`: atlas de oito frames 32×32.
- `idle-10x.gif`: quatro frames, ciclo 1.100 ms.
- `walk-10x.gif`: quatro frames, ciclo 520 ms.
- `preview-strip-6x.png`: filmstrip de diagnóstico, idle antes da caminhada.

Uma direção sudoeste. Corpo, mãos, pipa e rabiola preservados no mesmo grupo para manter cordas e encaixes. Pernas alternam em layers próprios; juntas sobrepostas evitam vãos. O movimento de repouso é reduzido a um pixel para essa escala. Prévia ampliada por nearest-neighbor.

Sem integração no jogo nem calibração de velocidade real. A versão 64×64 permanece preservada como base; usuário mudou o foco para 32 antes da revisão final daquela animação.
