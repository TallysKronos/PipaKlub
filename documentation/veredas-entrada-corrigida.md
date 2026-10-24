# Correção da entrada das Veredas — 24/10/2026

A seta azul do parque era desenhada acima do ponto de passagem, mas não tinha
alvo de clique próprio. Um clique nela virava um destino comum no chão, deslocado
da área que dispara a transição. O seletor de destinos alcançava o ponto exato.

O renderer agora registra um alvo de 56×60 pixels lógicos sobre cada seta,
contendo a ação e o destino do portal. O clique encaminha Kael à passagem
correta; ao selecionar uma saída explicitamente, a aproximação também confirma
a interação. O botão perto da saída passou a indicar “Entrar nas Veredas · E”.

Conferência manual no ambiente local isolado: Jardim → Clareira pelo seletor;
Veredas → Clareira e Clareira → Veredas clicando diretamente nas setas. Chegada
confirmada na interface, sem avisos/erros no console. Evidência em
`art/ui-reviews/veredas-entry-fix/arrival.png`. Builds Worker e Pages concluídos.
Sem suítes automatizadas e sem alterações de banco ou regras de combate.
