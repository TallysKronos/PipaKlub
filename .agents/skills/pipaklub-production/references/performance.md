# Desempenho na engine atual

## Diferencie o sintoma

| Sintoma | Evidência a coletar |
| --- | --- |
| Tela inteira engasga | Frame time, long tasks, CPU/renderização, memória/GC |
| Movimento próprio responde, adversário salta | RTT, chegada/idade de snapshots, jitter, reconexão e interpolação |
| Entrada em conta/mapa demora | Tempos HTTP e disponibilidade do serviço/banco |

Ping de 140 ms não é frame time de 140 ms. Modo leve pode reduzir custo visual, mas não encurta a distância ao servidor. Não conclua que o gargalo é GPU com base apenas em FPS ou duração de um callback JavaScript.

## Onde medir

- `src/index.html`: loop `frame`, desenho Canvas, cache de cenário, limite de densidade e modo leve.
- `src/frame-health.js`: estimativa de FPS e acionamento do modo leve; não é profiler de CPU/GPU.
- `src/menu-ui.js`: prévia animada da coleção e observação dos retratos visíveis.
- `src/network-view.js`: apresentação/interpolação dos snapshots.
- `src/realtime.js`: autenticação da sala, input e transmissão WebSocket.

Inspecione o código vigente antes de atribuir frequências ou limites. Use as ferramentas de performance do navegador disponíveis; em UI automatizada, respeite os controles e permissões do ambiente. Se não houver profiling detalhado, registre essa limitação em vez de inventar uma decomposição CPU/GPU.

## Procedimento

1. Defina cena repetível, build/commit, aparelho, navegador, viewport/DPR, qualidade e população. Separe carregamento frio de trecho aquecido. Registre duração e amostras.
2. Escolha a meta relevante: 60 FPS corresponde a aproximadamente 16,67 ms por frame; é uma meta, não uma medição. Para comparar, mantenha a mesma cena/configuração e prefira percentis além da média.
3. Identifique um custo sustentado ou pico reproduzível. Considere desenhos, criação de objetos, decodificação de imagens, acessos DOM e efeitos antes de propor pooling/cache. Não trate contagem de `drawImage` como medição direta de chamadas GPU.
4. Faça a menor mudança sustentada pela evidência. Preserve o passo da simulação, autoridade do servidor, cooldowns, XP, colisão e checkpoints. Efeitos visuais não devem pausar a partida online ou alterar seu relógio.
5. Compare antes/depois no mesmo cenário. Registre também regressões e limitações. Sem medição válida, entregue hipótese ou instrumentação, não uma promessa de ganho.

`frame-health.test.mjs` cobre o monitor; `network.test.mjs` e `realtime.test.mjs` cobrem contratos de rede. Para teste remoto, confira destino e escopo: `scripts/audit-demo-online.mjs --live` cria salas reais e valida acesso/RTT; não é benchmark de carga, GPU ou duas redes físicas. Não o execute por padrão para uma alteração documental ou visual local.

Não transforme os exemplos genéricos de orçamento da skill externa em bloqueios de CI sem baseline local medido. Capture apenas métricas necessárias, sem cookies, chaves privadas ou payloads de contas.
