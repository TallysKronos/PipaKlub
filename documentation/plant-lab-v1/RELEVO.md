# Relevo da bancada — morros e barrancos
Data: 2026-11-05.

Bancada independente de arte; não constitui área da campanha. Mantém a projeção top-down de células quadradas32×32 solicitada pelo dono, em vez de adotar a grade isométrica da campanha.

## Intenção
Dois morros baixos de leitura pixel 2D, com subidas visíveis pela frente:
- Oeste: terra, patamar1 e mirante2, rampas de duas células de largura.
- Leste: rocha, patamar2 com descanso1 e duas rampas em sequência.
- Corredor central livre para comparar escala com Kael e testar acesso aos dois lados.

Estrutura (norte acima):
```
  terra2            rocha2
  rampa1→2          rampa1→2
  terra1            descanso1
  rampa0→1          rampa0→1
       corredor0
```

## Contrato
Cota de 0 a12; altura visual16px por nível. Materiais, alturas e rampas são campos separados. Faces frontais existem apenas na diferença positiva para a superfície vizinha; bocas de rampas não recebem parede. Norte é a direção de subida. Movimento em passos de no máximo2px permite continuidade de rampa e bloqueia salto instantâneo de cota.

Plantas e Kael conservam coordenadas de raiz no plano lógico; a projeção aplica a altura do chão. Terreno elevado à frente recorta a porção encoberta dos sprites. Picking inverte a mesma projeção. Cotas de diagnóstico permitem conferir a estrutura sem depender da textura.

Layouts antigos importam com relevo plano. O botão Morros de exemplo preserva plantas e posição de Kael; muda cotas, rampas e pisos dos acessos. Desfazer restaura a composição inteira.

## Conferência
- 12 testes Node: modelo, exportação, rotas, migração antiga, faces internas, boca de rampa, continuidade, subida/descida dos dois morros, barreiras, picking e oclusão.
- 13 fluxos do editor existentes e quatro resoluções: sem erros de navegador.
- Teste de relevo no navegador: pintar cota/material, desfazer, remover/criar rampa e exemplo preservando plantas.
- Capturas gerais, cotas e juntas a2×, sem plantas ou Kael encobrindo os encontros.
- Godot4.7.2: importação e inicialização sem erro; assertions nativas de subida, descida, bloqueio e picking.

## Limites
Materiais ainda procedurais, sem tileset de arte final. Sem água, eventos ou alteração da campanha. Sem colisão de vegetação e sem ciclo de caminhada. O editor nativo não recebeu playtest manual completo; a validação nativa foi headless. Oclusão usa superfícies retangulares desta projeção; não é um sistema genérico de encostas diagonais.


## Edição atrás dos barrancos

O botão **Editar atrás dos barrancos** revela a composição sem alterar os dados. Escolha **Apoio** (0–12) para plantar em uma superfície real dessa cota, mesmo encoberta por terreno mais alto à frente. Mover, apagar e selecionar também enxergam os objetos ocultos. No modo Testar a oclusão volta automaticamente. O modo de revelação não é exportado como aparência do jogo; posições e alturas são preservadas.

Teste específico: `node tools/plant-lab/behind-ui-check.mjs`; capturas `editar-atras-revelado.png` e `editar-atras-teste-normal.png`.
