# Ícones de aquisição · Soulmonsters

Dois arquivos Aseprite editáveis e PNGs nativos exportados para `godot/assets/ui/key-items/`.

## Especificação

- Canvas: 128×128 RGBA; fundo transparente; alfa apenas 0 ou 255.
- Projeção: três quartos suave, mesma inclinação nos dois itens; luz superior esquerda.
- Carteira: papel creme, faixa azul, retrato resumido e brasão de pipa. Sem texto rasterizado.
- Porta-emblemas: estojo azul, fecho dourado e 12 cavidades em losango. Sem conquistas preenchidas.
- Paleta compartilhada de 13 cores: `#0c1827`, `#20364c`, `#385571`, `#56778b`, `#63cbd5`, `#b5eced`, `#fff3d4`, `#e4d3a0`, `#ad8b63`, `#edb24d`, `#fff0a0`, `#f3ba8e`, `#bc785a`.
- Silhuetas ocupam aproximadamente 104×92 pixels, com margem; contorno escuro e clusters opacos. Não há resize de concept nem antialiasing no arquivo.

Produzidos pelo Aseprite AI Artist em modo headless, desenhados no canvas de 128×128 e exportados pelo próprio Aseprite. A análise de paleta do conector não encontrou cores externas ou pares redundantes. A ferramenta `validate` citada pelo manual não estava exposta nesta sessão: dimensão, número de cores e transparência foram verificados pelo teste Godot `key_item_banner_checks.gd`.

## Crítica independente

Agente `key_item_pixel_critic`, sem editar os arquivos: carteira **8/10**, porta-emblemas **7,5/10**, nenhum bloqueio. Reconheceu documento com retrato/pipa e estojo com doze espaços, projeção e luz coerentes. Observação mantida: os centros claros das cavidades podem lembrar emblemas já instalados. O contador 0/12 e os espaços apagados na carteira comunicam o estado de conquista. Conforme o critério da skill, não houve rodada adicional após aprovação acima de 7/10 e sem bloqueios.
