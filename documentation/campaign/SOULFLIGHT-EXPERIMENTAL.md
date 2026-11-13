# Soulflight experimental

Ative PIPAKLUB_SOULFLIGHT=1 antes de iniciar o Godot. Sem essa variável, a física legada permanece ativa.
O protótipo está integrado aos duelos individuais. As batalhas em grupo do Morro usam o legado.

Z e RT recolhem linha. C e LT soltam linha. R e RB continuam acionando o puxão especial.
Os atalhos Z/C são omitidos quando entram em conflito com as teclas personalizadas.

A linha usa 24 segmentos Verlet e oito passagens de restrições por atualização.
O voo preserva impulso e recebe tração contínua. A IA utiliza o mesmo movimento.
A geometria simulada determina cruzamentos e o corte mantém os custos e regras existentes.
O marcador claro mostra contato e a faísca dourada mostra oportunidade de corte.
Um pulso discreto indica tensão sem mudar a cor ou a espessura da linha.

Testes executados localmente
- soulflight_checks — folga, tensão, soltura, planagem, reversão, IA, cruzamento, corte e esquiva.
- morro_checks — 377 verificações passaram.
- evolution_checks — requisitos, consumo único, confirmação, cancelamento e ritual.

Pendências
- Playtest completo com controle físico e calibração de game feel.
- Paridade com duelos em grupo e benchmark de desempenho.
- Comparação gráfica contínua e teste sistemático em várias taxas de quadros.
- Concept Faye v2 e raposa ártica ainda aguardam produção de sprites e integração.
