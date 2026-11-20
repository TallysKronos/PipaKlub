# Alvacordo — receber dano em batalha

Reação de dano em 192×192, três quartos olhando à esquerda. O impacto vem do oponente à esquerda; a parte superior recua para a direita e volta à postura aprovada. A versão direita é o espelho horizontal exato de cada célula.

## Entrega

- `alvacordo-damage-left.aseprite` e `alvacordo-damage-right.aseprite`: fontes editáveis com oito quadros, camada de arte, original preservado oculto e fundos de inspeção ocultos.
- `damage-left.png` + `damage-left.json` e `damage-right.png` + `damage-right.json`: atlas horizontal de 1536×192, oito células de 192×192, sem trim ou padding.
- `damage-left-2x.gif`: preview transparente de 384×384.
- `damage-left-filmstrip-light.png` e `damage-left-filmstrip-magenta.png`: inspeção dos oito quadros sobre fundos contrastantes, 1536×192.
- `snapshot-before-review.aseprite`: cópia anterior à revisão independente; nenhuma edição de polish foi aplicada depois desse snapshot.

## Timing

Tag `damage`, reprodução única, JSON frames 0–7, total 720ms. Durações em milissegundos: `50,110,50,80,90,100,80,160`.

1. Postura pronta original.
2. Impacto: recuo máximo, compressão e olho fechado; hold de 110ms representa o hitstop.
3. Recuo residual.
4. Começo da recuperação, olho ainda fechado.
5. Retorno da expressão e do tronco.
6. Recuperação lenta.
7. Pequeno overshoot contrário de 1px na parte superior.
8. Postura original exata, mantida por 160ms.

Pivô/slice `origin`: `(96,181)`; baseline y=181. O runtime deve reproduzir uma vez e retornar ao idle. O hold desenhado não exige freeze adicional; se houver hitstop global, evitar somá-lo duas vezes. Sem flash branco ou tint que esconda a personagem.

## Construção e verificações

Todos os pixels e exports foram escritos pelo MCP Aseprite em headless. A fonte aprovada `battle-pixel-v1/alvacordo-battle-192.png` foi preservada. A reação usa deslocamento contínuo e progressivo ao longo do corpo: cabeça até 11px, tórax aproximadamente 8px, quadril aproximadamente 4px, pés 0px, com compressão vertical máxima de 3px. As transições são graduais, sem recortar peças retangulares nem abrir juntas; não houve separação de membros que exigisse inventar volumes ocultos. A expressão recebeu uma alteração localizada para fechar o olho no impacto.

A animação representa um impacto curto contra a armadura; não contém queda ou afastamento dos pés. Armas, rosto e armadura mantêm o desenho aprovado, com a deformação limitada ao recuo/compressão. O original oculto na fonte direita permanece como referência de origem à esquerda; a camada `pose-damage` é a direção correta para exportar.

Inspeção visual realizada nas tiras claras e magenta. Conferência dos PNGs finais: 24 cores opacas, zero pixels abaixo de y181, região y160–191 idêntica ao original em todos os quadros, primeiro e último quadro exatamente iguais ao original, espelho direito com zero pixels divergentes. JSON contém pivô correto, durações individuais e repeat=1. A cor magenta existe apenas no fundo de inspeção e não entra nos atlases transparentes.

O servidor não expôs uma ferramenta `validate`; foram usadas as operações disponíveis de inspeção, leitura dos exports e conferência mecânica. Revisão independente de `alvacordo_pixel_critic`: **8/10, sem BLOCKING**. Confirmou recuo de cabeça/tórax, olho fechado, pés fixos, quadros inicial/final iguais ao master e ausência de faixas ou cortes no desenho. Nenhum pixel mudou depois dessa revisão.
