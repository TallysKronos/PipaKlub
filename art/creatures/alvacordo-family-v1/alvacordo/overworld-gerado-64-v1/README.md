# Alvacordo — overworld gerado e convertido para 64×64

Novo piloto autorizado pelo autor: gerar uma base já com aparência pixel e adaptar/corrigir os quadros, em vez de reconstruir o personagem por partes. Referência própria: `../concept-v4/concept.png`, aprovado. Geração pelo image_gen integrado, prompt integral em `prompt.txt`; saída original preservada em `prancha-gerada.png`.

## Processo e arquivos

1. Prancha gerada 2×2, uma direção sudoeste e quatro poses de caminhada. Original 1262×1246 RGBA, preservado sem alterações.
2. Importação/corte dos quatro painéis no Aseprite; mesma escala de conversão para canvas 64×64. Esta conversão de raster gerado é uma escolha explícita do autor para o experimento.
3. Paleta curada com 17 slots; 16 cores usadas. Remapeamento no Aseprite, alpha binário com limiar 128 e remoção dos resíduos semitransparentes. Apoio alinhado em y60, deslocamentos verticais por frame: +1, +3, 0, +2.
4. Atlas e prévia com tempos 160/110/160/110 ms, tag `walk-so`. Ciclo 540 ms.

- `alvacordo-walk-64.aseprite`: fonte editável, uma camada `pixels`, quatro frames.
- `alvacordo-walk-64.png` / `.json`: sheet horizontal 256×64 e atlas.
- `preview-6x.gif` / `.png`: ampliação nearest-neighbor.
- `prancha-gerada.png`: saída original da geração.
- `prompt.txt`: prompt da geração.
- `validacao.json` / `revisao.md`: medidas e revisão independente.

## Limites do piloto

O rosto e a gola mantêm mais identidade do que a primeira reconstrução manual. Ainda há variação leve na cabeça e nas placas entre quadros; detalhes do olho e da moldura do peito se perdem em 64×64. A caminhada é um preview de uma direção, não um conjunto final de oito direções. Não integrado ao jogo. Aprovação do autor pendente.

O conceito v4 e os pilotos anteriores permanecem intactos. Não há afirmação de pixels inteiramente desenhados à mão: esta versão deriva de geração e conversão, com limpeza no Aseprite.
