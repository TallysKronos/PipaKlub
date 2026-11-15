# Loja de itens da Linha & Papel

Ao interagir com o lojista, a campanha abre a loja de itens em tela cheia. A exploração fica pausada durante a compra. Voltar ou Escape fecha a tela e retoma a posição e os controles da loja.

A HUD reaproveita o kit azul Carretel, com os mesmos painéis, fontes, foco e escala da interface atual. O catálogo permite filtrar cuidados e materiais, escolher a quantidade, consultar o total e ver quantas unidades estão na mochila. Saldo insuficiente desabilita a compra. O retorno da operação apresenta sucesso ou erro de gravação.

## Catálogo inicial

| Item | Moedas por unidade |
| --- | --- |
| Kit de Remendo | 12 |
| Papel de seda | 4 |
| Vareta de bambu | 5 |
| Cola de reparo | 6 |
| Linha encerada | 8 |

O preço do kit acompanha PartnerCare.PRICE. Os quatro preços de materiais foram definidos como valores iniciais para revisão de economia. A seleção usa somente itens já reconhecidos pelo inventário. O kit conserva seu efeito existente nos cuidados. Os materiais comprados entram na mochila, com a mesma função que tinham antes.

## Assets

Foram criados seis ícones próprios, incluindo moeda, com a ferramenta integrada ImageGen. O original está em fontes/itens-imagegen.png e o prompt completo em fontes/PROMPT.md. A folha 3 × 2 foi recortada, limpa de alfa residual e normalizada para ícones 256 × 256, com 16 px de margem mínima, pelo script shop_item_assets.gd.

Os PNGs finais ficam em godot/assets/ui/loja-itens-v1/. A loja e a mochila compartilham os mesmos ícones. Os ícones usam contorno azul-escuro, metal claro, detalhes verde-água e laranja para acompanhar o interior tecnológico.

## Compra e salvamento

ItemShop valida a cena, o item, o preço do catálogo, o saldo e a quantidade inteira de 1 a 99 unidades por compra. O custo, o inventário e o recibo são aplicados pelo Session.commit_operation existente. Repetir o mesmo recibo retorna already_applied. Uma falha de salvamento preserva o estado publicado, permitindo tentar a mesma operação novamente.

A interface recebe cópias do estado e atualiza os valores após o resultado da operação. A loja não usa preços vindos dos botões.

## Verificação no projeto principal

- 31 verificações de compra, incluindo múltiplas unidades, saldo, valores inválidos, recibo repetido, falha de gravação, nova tentativa e retomada.
- 24 verificações de interface e integração, com teclado simulado, foco, filtros, retorno, compra e persistência.
- 24 verificações do fluxo de entrada pelo bairro, acesso ao lojista, fechamento e saída.
- 25 verificações do sistema de cuidados.
- 45 verificações do cômodo e navegação, com 4.848 amostras alcançáveis.

Capturas em revisao/ incluem a tela inicial, a compra confirmada e o saldo insuficiente. Foram conferidas janelas 960 × 540, 1280 × 720 e 1920 × 1080. O teclado foi simulado por eventos de ação e os callbacks dos botões foram exercitados. Controle físico não foi utilizado.

Os testes usaram saves isolados em godot/.godot/.

## Reprodução

```powershell
godot --headless --path godot --script tests/item_shop_checks.gd
godot --path godot --script tools/item_shop_capture.gd --rendering-method gl_compatibility
godot --headless --path godot --script tests/partner_care_checks.gd
godot --headless --path godot --script tests/shop_modern_checks.gd
godot --path godot --script tools/shop_flow_capture.gd --rendering-method gl_compatibility
```
