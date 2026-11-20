# Alvacordo — teste nativo de 32×32

Pose estática desenhada diretamente na grade de 32×32 do Aseprite, usando o concept-v4 aprovado como referência de identidade. Não é uma redução do sprite de 64×64.

Prioridades: cabeça canina adulta com olhos estreitos, gola branca ampla, peitoral com motivo de pipa, arcos nos antebraços e rabiola curva. As peças menores da armadura foram agrupadas em massas de cor para preservar a leitura. Luz superior esquerda; contorno externo escuro de um pixel e divisões internas seletivas.

Arquivos: `alvacordo-32.png` nativo transparente; `alvacordo-32-12x.png` ampliação inteira sem suavização; `alvacordo-32.aseprite` fonte com três camadas editáveis (rabiola, corpo e arcos). `PixelSpec.json` registra a grade de construção; o encaixe final do arco direito acrescenta uma grade 3×3 em (21,21): XGX / WGG / XGX.

Validação: 32×32, 10 cores visíveis, alpha binário, 512 pixels ocupados. Análise de paleta do Aseprite sem cores externas. O conector não disponibiliza a operação validate; as dimensões e o alpha foram medidos no PNG exportado.

Estado: teste visual para avaliação do usuário. Não integrado ao jogo e sem animações nesta etapa.
