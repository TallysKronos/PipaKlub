# Papisco — animações na escala da família

Canvas transparente de 64×64; pivô comum `(32,62)`, baseline y=62. Papisco mede 39px na pose neutra, contra aproximadamente 61px do Alvacordo adulto. A cabeça grande, membros curtos e orelha dobrada mantêm a leitura infantil. Idle varia até 40px com a respiração; victory sobe durante o salto.

## Arquivos

- `papisco-left.png` / `.json` e `papisco-right.png` / `.json`: atlas horizontal de 2048×64, 32 células de 64×64 sem trim nem padding. Filtragem nearest-neighbor.
- `papisco-left-64.aseprite` e `papisco-right-64.aseprite`: fontes finais de 32 frames; direita é espelho horizontal exato por célula.
- `papisco-left-rig-64.aseprite`: fonte com seis partes separadas para edição.
- `papisco-master-64.png`: pose neutra nativa.
- `idle`, `walk`, `victory`, `defeat` + `-left-4x.gif`: previews de 256×256, oito quadros cada.
- Os quatro `-left-filmstrip-4x.png` exibem os oito quadros de cada estado (2048×256).

## Estados e timing

| Estado | Frames Aseprite | Frames JSON | Duração | Reprodução |
|---|---|---|---|---|
| idle | 1–8 | 0–7 | 1520ms | loop |
| walk | 9–16 | 8–15 | 760ms | loop |
| victory | 17–24 | 16–23 | 1330ms | uma vez, manter último |
| defeat | 25–32 | 24–31 | 2200ms | uma vez, manter último |

O JSON inclui a slice `origin` com pivô `(32,62)` e repeat=1 nos estados finais. O runtime deve respeitar as durações e impedir o loop de victory/defeat.

## Arte e limites

Reaproveita o próprio Papisco de `overworld-64-v1`, readaptado no Aseprite à altura infantil e à escala compartilhada. Paleta original de 12 cores; olhos âmbar, peito-pipa marfim, cordas vermelhas, duas bandeirolas claras/teal e contorno escuro preservados. Construção e exports feitos pelo MCP Aseprite em headless. Redução inicial autorizada via reference fit-contain e reparo localizado; nenhum processamento externo de imagem.

A vista é três quartos esquerda/direita por espelhamento; não é um conjunto de oito direções. Victory é um pequeno salto com pata erguida; defeat abaixa cabeça e pata e mantém a personagem de pé, sem tombo lateral. Detalhes pequenos do conceito foram simplificados para o overworld. O rig usa movimentos discretos por partes, sem redesenho integral de cada pose.

Snapshots de revisão (`before-hip-fix.aseprite`, `hip-a-before.png`, `hip-b-after.png`, `victory-f18-before.png`, `victory-f18-after.png`) são evidências, não assets de runtime. A correção de quadril só preenche a conexão em idle3–5 e walk8; a correção de victory2 mantém os pés na baseline durante a antecipação.

O servidor não publicou uma ferramenta `validate`; as verificações disponíveis foram `sprite_info`, leitura dos cels, previews, filmstrips e inspeção dos exports.
