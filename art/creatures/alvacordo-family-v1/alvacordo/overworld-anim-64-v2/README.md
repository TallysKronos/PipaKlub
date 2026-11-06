# Alvacordo — idle, walk, victory e defeat

32 quadros nativos de 64×64, 12 cores visíveis, uma direção sudoeste. Fonte com uma camada de quadros editáveis; o rig anterior usado para montar os movimentos permanece em ../overworld-anim-64-v1/. O rosto recebe os ajustes do master v6; não foi gerado novamente entre quadros.

| Tag | Quadros Aseprite | Duração | Reprodução |
| --- | --- | --- | --- |
| idle | 1–8 | 1440 ms | ciclo |
| walk | 9–16 | 920 ms | ciclo |
| victory | 17–24 | 1540 ms | uma vez, retorna à pose |
| defeat | 25–32 | 1860 ms | uma vez, segura último quadro |

Idle e walk retomam os ciclos v1 com o rosto atualizado. Vitória tem antecipação curta, arco do braço próximo levantado, sustentação e recuperação. Derrota fecha o olho, abaixa cabeça e torso, recolhe pernas e segura a pose abatida. Deslocamentos inteiros e rearticulação por grades preservam os pixels e a iluminação, sem rotação interpolada ou escala fracionária.

Abra index.html para visualizar os quatro movimentos no tamanho nativo ou ampliados. O player respeita as ações de uma vez; os GIFs são prévias e podem repetir conforme o visualizador. Atlas alvacordo-64.png + alvacordo-64.json com 32 células de 64×64. Fonte alvacordo-64.aseprite. Não integrado ao jogo nesta entrega; a velocidade do walk ainda precisa ser calibrada com a locomoção no runtime.

validacao-grades.json registra as medidas dos quadros. O conector não expõe validate; foram usados análise de paleta e medição dos exports.

Após alerta do usuário foram corrigidos os punhos cortados em idle4–6, walk3/7, victory3–7, além do resíduo do braço abaixado em victory.95pixels em11quadros; snapshots e revisão em revisao-recortes/REVISAO.md. Atlas, GIFs e fonte atualizados. Conectividade em oito vizinhos não comprovava o punho preenchido, pois o arco ligava as partes; os quadros agora foram comparados em fundos claro e magenta. Pose/rosto/escala e tempos preservados.
