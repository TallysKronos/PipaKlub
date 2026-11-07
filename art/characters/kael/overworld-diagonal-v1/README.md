# Kael — overworld diagonal v1
Duas poses estáticas em câmera elevada: frente SW e costas NW, canvas80×80. Kael foi adaptado ao acabamento de pixel art aprovado para os Soulmonsters, preservando a identidade humana e roupa do concept mangá v4.

## Entrega
- `frente-sw.png`, `costas-nw.png`: poses nativas transparentes.
- `kael-overworld-diagonal.aseprite`: fonte editável, dois frames de vista (não animação).
- `preview-cinza-5x.png`, `prancha.aseprite`: comparação frontal/traseira ampliada e editável.
- `escala-4x.png`, `comparacao-escala.aseprite`: Kael, Papisco, Gambalhote e Alvacordo, nesta ordem, com chão alinhado.
- `index.html`: comparação de fundos, zoom e downloads.
- `geracao.png`, `prompt.txt`, `normalizacao.json`: base e histórico.
- `validacao.json`: medidas reais do PNG.

## Identidade e produção
Cabelo azul-marinho em quiff alto, rosto juvenil, jaqueta azul com faixas claras nas mangas, fones turquesa ao pescoço, camiseta preta, calça cinza-azulada com uma faixa na coxa esquerda, duas tiras presas à cintura e botas escuras de sola clara.

image_gen integrada para a base em duas vistas. Aseprite MCP headless para recortes de mesmo tamanho/mesma escala por par, paleta própria de24cores, alpha binário e posicionamento. A base foi reduzida a22×48 com margem adicional para canvas80×80. Trata-se de adaptação de base gerada, não desenho integral manual nem recuperação comprovada de grelha.

Pivô proposto (40,65). A comparação com os Soulmonsters usa pixels nativos sem mudar suas escalas. A altura de Kael foi definida em48px incluindo cabelo; detalhes de olhos/expressão são discretos no tamanho nativo. Escala no mapa, colisão, pivô em movimento e runtime ainda precisam de teste. Não foi alterado o sprite atual do jogo.

## Revisão independente
8/10, sem achados BLOCKING. Reconhecimento por cabelo/jaqueta/fones, câmera, escala entre vistas e continuidade de mãos, pernas e botas considerados bons, incluindo fundo claro. Duas tiras distinguíveis e faixa de coxa não duplicada. Nenhum pixel alterado após a revisão.

Esta entrega contém poses estáticas. Não houve animação, integração, commit ou push. Próxima etapa após aprovação visual: conferir Kael no mapa e produzir idle/walk.
