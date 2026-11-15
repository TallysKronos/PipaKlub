# Linha & Papel · interior

O quadro-chave usa os volumes da loja jogável como referência e os materiais da fachada-piloto. O rodapé coral, os vidros azuis, o reboco creme e a parede verde-água ligam os dois lados da loja. O jogador entra pelo vidro frontal, vê a vitrine vertical de pipas à esquerda e tem um corredor livre até o caixa. As duas mesas com bancos e tapetes ficam juntas à direita, onde as cartas estão à vista.

| Zona | Elementos conferidos |
| --- | --- |
| Entrada | Duas folhas de vidro, puxadores, capacho e circulação desde a porta. |
| Lateral esquerda | Janela, exposição vertical de pipas e gôndola baixa de papel e acessórios. |
| Fundo | Prateleiras com rolos e carretéis, três quadros de pipa e caixa com terminal. |
| Lateral direita | Segunda janela, mais prateleiras e duas mesas comunitárias com cartas e bancos. |

O estudo de acabamento veio do ImageGen com a captura da loja atual, a fachada-piloto e o interior do laboratório como entradas. Depois de normalizar a base para a paleta do projeto, o Aseprite recebeu uma camada para o acabamento da luz no piso e nas paredes e para o capacho.

- [Quadro-chave transparente](quadro-chave.png) e [fonte editável Aseprite](quadro-chave.aseprite).
- [Comparativo com o interior atual](comparativo.png).
- Convivência em [cor 1×](convivencia-nativa.png), [cor 2×](convivencia-cor-2x.png), [cinza 1×](convivencia-cinza.png) e [cinza 2×](convivencia-cinza-2x.png). As pranchas usam Kael, Rabbito e Lia em escala nativa.
- [Verificação da arte](verificacao.json) com canvas 976 × 680, 88 cores da paleta mestra e da extensão, zero pixels semitransparentes e zero pixels opacos isolados.
- [Fonte e prompt do ImageGen](fontes/PROMPT.md).

A posição desenhada do balcão e dos móveis é visual. Em uma etapa de integração, os pontos da planta e oclusores precisam ser calibrados contra a cena `kite-shop`. Esta entrega é o quadro-chave para aprovação.

Comandos de reprodução na raiz:

```powershell
godot --headless --path godot --script tools/loja_interior_base.gd
godot --path godot --script tools/loja_interior_revisao.gd --rendering-method gl_compatibility
```
