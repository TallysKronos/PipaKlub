# A — Seda & vareta

Hipótese: a construção da pipa organiza o painel. O eixo superior sustenta a informação; uma união fixa firma a superfície; rabiola curta indica foco. Assimetria leve e superfície clara, sem textura competindo com o texto.

| Papel | Cor |
| --- | --- |
| Seda / superfície | `#fff5dc` |
| Tinta / texto principal | `#163d40` |
| Linha / ação estrutural | `#087b7e` |
| Foco / rabiola | `#c05528` |
| Vareta / sustentação | `#a77f43` |

Tipografia: Barlow Condensed Bold para títulos; Nunito para dados. Ícones lineares próprios, sempre com rótulo. A assinatura não depende de desenhar uma pipa inteira em todo componente.

Composição: informação apoiada em cantos; centro do mundo livre. Na pausa, consulta lateral e oito destinos em duas colunas. O foco tem uma linha inferior firme e rabiola, permanecendo visível sem movimento ou cor. Nó e vareta ficam fixos quando a placa cresce: futura implementação em slices/Control, sem esticar ornamentos.

Movimento proposto, ainda não implementado: entrada abre a superfície a partir do eixo por cerca de 180 ms; conteúdo permanece firme; saída recolhe em 120 ms. Texto não sofre escala ou balanço. Em movimento reduzido, apenas opacidade curta ou troca imediata com foco estável.

Conferir: papel claro sobre céu e chão claros; legibilidade da Linha contra a superfície; nó fixo em textos longos; foco em cinza. Risco: parecer pergaminho ou kit de bambu se a estrutura virar moldura ornamental.

As mesmas fixtures e limites do [brief comum](../BRIEF.md). Não é direção aprovada, Theme ou HUD integrada. Contrato de input proposto no brief comum; não houve teste físico.
