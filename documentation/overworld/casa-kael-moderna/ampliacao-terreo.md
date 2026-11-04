# Térreo ampliado e porta do quarto da mãe

## 1. Arquivos

`house_modern.gd` prepara o layout Godot do térreo em cópia, sem alterar o conteúdo legado. O RoomView usa essa preparação. Piso de 12×9 para 15×11 células (+52,8%); walkable ampliado junto com o desenho, câmera ajustada e todos os retângulos dos móveis escalados uniformemente. Porta nova na parede do fundo, junto à cozinha, com moldura clara, madeira e detalhe azul; hall com pequeno capacho. Fontes existentes reaproveitadas, sem novos bitmaps ou mudanças no quarto superior. Brief em `art/casa-kael-moderna-v1/ampliacao-terreo.md`.

## 2. Resultado automático

```text
CASA MODERNA 79 checks; bedroom 1807, home 4680 reachable samples; 0 failures; no save access
CAMPAIGN CHECKS: 206 checks, 0 failures
CAMPAIGN VIEW CHECKS: 30 checks, 0 failures
```

Todos com saída 0. O teste geral de views ainda emite o diagnóstico de 1 recurso em uso ao sair, já registrado na entrega anterior. O teste da casa e as capturas nativas não emitiram erro de script ou shader. Conferidos os hotspots anteriores, a área adicionada, aproximação da porta e ausência de mutação do layout fonte. Preparar novamente um layout já ampliado não duplica a porta ou aplica novo zoom.

## 3. Capturas

`home-ampliado-geometria-*` e `home-ampliado-arte-*`: geral com/sem atores, detalhes a 2× da porta da mãe, porta externa, escada no pé e no topo, cozinha, jantar e sofá, mais poses de oclusão. `terreo-ampliado-antes-depois.png`: comparação. `abertura/10-sala-ampliada.png`: cena real no frontend. PNGs individuais em 1280×720, registrados em `evidence.json`.

## 4. Percurso

Busca de alcance pelo `_safe` real do personagem com 4.680 amostras alcançáveis. Inclui o novo hall, a frente da porta da mãe e a circulação adicionada na frente da escada. A cena real da abertura foi executada em progresso isolado, incluindo o movimento da mãe no térreo. O percurso de todos os caminhos foi automatizado; não houve uma sessão manual com controle físico.

## 5. História e itens

Somente a leitura arquitetônica de uma casa familiar foi ampliada, por pedido explícito do dono. Sem novo item, diálogo, revelação ou recompensa. A porta indica o quarto da mãe, mas seu interior não está construído e não há hotspot de entrada fictício.

## 6. Integração

Integrado ao RoomView Godot. Mantidos os pontos existentes da escada, saída e encenação para compatibilidade com o progresso anterior. Não altera saves ou navegação do legado web.

## 7. Dúvidas

Sem bloqueio para esta reforma. O interior do quarto da mãe é uma próxima área separada, a definir quando solicitado.

## 8. Não verificado

Não houve exportação Windows/Steam, teste com controle físico, reedição do filme pré-renderizado ou atualização do renderer web. A porta permanece fechada; esta entrega não cria outro cômodo jogável. Não houve push ou deploy.
