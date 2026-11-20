# Alvacordo — ataque de batalha

Animação192×192,24cores,10frames/950ms, left e right. Direita é espelho exato por célula. Pose inicial e final idênticas ao master aprovado battle-pixel-v1/alvacordo-battle-192.png. Pivô proposto (96,181), pés na referência y181. Tag attack com repeat1.

Base: vídeo localH3 em ../battle-attack-h3-v1/. Foram extraídas10amostras adicionais, e selecionadas8 sem rastros cobrindo o corpo, nos tempos1,30;1,43;1,53;1,65;3,25;3,70;3,95;4,20s. Master abre e fecha a sequência. As poses foram importadas Aseprite com uma transformação comum512→192, sem auto-fit ou mudança individual de escala. Fundo magenta removido por chave de cor, cores normalizadas para a mesma paleta24 do master. Todas as poses derivadas do vídeo recebem o mesmo deslocamento vertical−1px para manter a referência de chão. O resultado é adaptação de vídeo, não desenho manual de todas as poses.

Guarda → antecipação → corte com abertura dos braços → contragolpe lateral → recuperação → guarda. O tempo do vídeo foi comprimido para ação de batalha; as partes estáticas longas e os frames com grandes efeitos foram descartados. O contragolpe muda a orientação do torso brevemente para perfil. Essa mudança é rápida e deve ser avaliada pelo usuário em reprodução.

## Arquivos

attack-left/right.aseprite: quadros editáveis. attack-left/right.png e .json: atlassemtrim/padding,10células192×192. attack-left-2x.gif: prévia ampliada. review/attack-light.png e attack-magenta.png: sequência final,5colunas×2linhas. references mantém amostras brutas/tempos, sem substituir o vídeo original.

## Correção e revisão

Primeira revisão6,5/10 apontou cordas interrompidas no contragolpeF6. Snapshotantes em review/antes-cordas.aseprite/.png. Removidos fragmentos vermelhos soltos e reconstruídas as cordas entre fixações; pixels de mãos e armadura preservados por oclusão. Comparação independente prefere review/a.png (corrigido) a b.png (original),7,5/10, sem bloqueadores restantes nesta correção. Demais9quadros preservados. A revisão de ritmo foi por filmstrip/tempos; a transição frontal→perfil→frontal merece avaliação em movimento na prévia.

Fontes transparentes e paleta verificadas. Nenhum código do jogo foi alterado, nenhuma integração ou aprovação final desta animação é implícita. O conector não disponibiliza validate; foram usados palette analyze, métricas dos exports e inspeção de fundos contrastantes.
