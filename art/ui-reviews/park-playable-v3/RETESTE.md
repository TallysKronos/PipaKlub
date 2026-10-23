# Reteste dos achados da auditoria

Revisão local, 22/10/2026. Navegador nativo, viewport capturado de 1166×884. Não houve publicação nem alteração de conta.

| Achado | Correção | Verificação |
|---|---|---|
| U01: teclado depende do clique e perde foco após botão | Foco inicial no Canvas, comandos de exploração fora dos diálogos, foco devolvido por controles e fechamento de painel | Seta direita logo após carregar; pausa do vento seguida de seta esquerda; Escape abre/fecha painel |
| U02: clique na placa vira destino atrás dela | Seleção por área visual, aproximação por rota segura, interação ao chegar; mapa com destinos DOM acessíveis | Mapa usado para localizar fibras; coleta depende de confirmação |
| U03: protagonista desaparece atrás da placa | Opacidade contextual aplicada a props além de árvores/coreto e anel de localização | Verificação visual na versão revisada; marcador permanece na posição dos pés |
| U04: entrada do coreto fechada | Remoção do bloco integral, bases de colunas, banco reposicionado | Rota até o NPC e teste de ponto transitável na escada |
| U05: mensagem de chegada persiste enquanto anda | Movimento manual substitui a mensagem e cancela destino/interação pendente | Mensagem “Explorando” após comando de teclado |

## Passeio completo

- Aceite com Assis confirmado no diálogo.
- Coleta oeste explícita: inventário 1/3.
- Salvar pelo menu, recarregar página, carregar pelo menu: 1/3 e posição restaurados.
- Coleta norte: 2/3; destino da fibra oeste já ausente do mapa.
- Coleta leste: 3/3; objetivo pede retorno ao professor.
- Retorno por rota ao coreto, conversa de tarefa concluída e recebimento do kit local.
- Nova conversa com Assis: agradecimento, sem botão para receber outro kit.
- Novo salvar/recarregar/carregar: 3/3 fibras e kit de reparo 1 preservados.
- Clique direto no painel ilustrado da placa: aproximação e abertura do mapa confirmadas.
- Rota do mapa até o banco: diálogo de descanso e confirmação concluídos, preservando o kit.
- Sons ativados/desativados pelo menu; indicador de estado confirmou ambas as ações. A qualidade sonora não foi avaliada por escuta.
- Prévia deixada em exploração, vento ativo, sons desativados e passeio completo salvo localmente.

O conjunto de testes automatizados adicional cobre o retorno sem atravessar sólidos, as três coletas únicas e a recompensa idempotente. As evidências finais de diálogo e inventário ficam nesta pasta.

## Limites preservados

As saídas têm nomes e explicam que a continuação está fora da prévia. Não foram adicionadas batalhas de produção, integração da oficina, atlas novos de oito direções ou ambiente sonoro final. Sons de interação/passos são opcionais. Não há medição de FPS ou teste em aparelho móvel real nesta validação.
