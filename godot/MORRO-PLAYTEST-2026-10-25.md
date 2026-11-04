# Morro do Sol — entrega jogável, 25/10/2026

## Percurso disponível

Após concluir a primeira pipa com o professor, a Rua dos Ventos permite entrar
no Morro do Sol. O comando de entrada aparece por proximidade. Os cinco lugares
são Praça da Chegada, Escadaria da Sombra, Laje dos Ventos, Mirante da Caixa-d’água
e Parque dos Ventos. Zeca, Bia, Juninho/Lia, Tião e Mikka usam seus diálogos originais.

WASD/setas ou analógico movem Kael; clique no chão calcula um caminho válido;
E/Enter ou A/× interage por proximidade. As passagens abrem depois da vitória.
A saída depois de Mikka retorna à rua; o jogador pode visitar o professor,
invocar Raio de sol com a nova rabiola ou seguir ao parque e às Veredas.
Retornar pelas cinco áreas e revisitar desafios também funciona.

## Combate e progresso

- Séries de duas vitórias nos quatro primeiros desafios e três contra Mikka.
- Juninho e Lia disputam simultaneamente, inclusive entre si. Eliminação,
  empate por tempo, intervalos, placar e desgaste persistente da armação.
- IA com estilos próprios e maestria/ajuste após derrotas, conforme regras originais.
- Moedas, estrelas, bônus de primeira vitória, XP do parceiro e do pipeiro.
- Rabiola de Mikka concedida uma vez, com alias para a receita Raio de sol já existente.
- Derrota permite revanche; fuga não dá recompensa; professor repara gratuitamente.
- Save inclui atores, placar e intervalo. Ao carregar, o combate aguarda Retomar.
- Feedback de cruzamento válido e HUD de todos os participantes.

O combate reaproveita o port local existente. Não é uma declaração de equivalência
integral ao servidor original: especializações, todas as manobras e demais assinaturas
continuam fora desta entrega.

## Evidência

| Verificação | Resultado |
| --- | --- |
| Percurso fonte: Novo jogo → professor/oficina → Morro → cidade/revisita → parque → Lacertubo → Nina → reparo | 198 verificações, zero falhas |
| Mesmo percurso executado contra o PCK exportado | 201 verificações, zero falhas |
| Novo processo carrega o save concluído da execução fonte | 9 verificações, zero falhas |
| Regras do Morro, incluindo 367 resultados gerados pelo JS original | 377 verificações, zero falhas |
| Colisões, todas as arestas exportadas, passagem fechada e limites de diálogo | 9386 verificações, zero falhas |
| Transações de fuga, derrota, revanche, recompensa única e roundtrip | 47 verificações, zero falhas |
| Regressão geral de campanha e persistência | 206 verificações, zero falhas |
| Integração anterior | 23 verificações, zero falhas |
| Entrada simulada | 19 verificações, zero falhas |
| Parque original | 1510 verificações, zero falhas |
| Cinco mapas e três lutadores carregados do PCK | Sem erros |
| Executável Windows em inicialização headless | Saída 0 |

O número do percurso varia com os encontros aleatórios no mato. A maioria das
9386 verificações são sondagens geométricas, não milhares de cenários de gameplay.
O percurso usa comandos e callbacks das telas, com navegação/estratégia roteirizadas;
não injeta parceiros, inventário, XP ou vitórias. Transações sintéticas são testes
separados e identificados. Saves usam diretórios exclusivos; saves reais não foram
alterados.

Capturas gráficas revisadas em 1280×720: os cinco mapas, três participantes e diálogo
longo. Limites de diálogo também verificados em 1024×768. Revisão humana de descoberta,
dificuldade, uso prolongado e controle físico continua necessária.

## Fluidez medida

Godot 4.7.2 Compatibility, Windows, RTX 3060, 1280×720, limite de 60 FPS.
Cinco mapas caminhando e uma batalha com três participantes: 60 frames de aquecimento
mais 150 amostras por cena. Medianas de 16,64–16,66 ms; p95 de 16,72–16,99 ms;
pico observado de 21,52 ms. Isso descreve este PC e estas amostras, não hardware mínimo.

A construção das cenas repetia testes de colisão em todas as arestas de um grafo
que já fora validado pelo exportador. Reutilizando esse grafo e aplicando apenas
o bloqueio dinâmico do portão, a construção dos mapas caiu de 161–387 ms para
49–177 ms em duas execuções no mesmo PC. As colisões continuam verificadas em cada
movimento real. Os carregamentos iniciais de mapa/batalha ainda existem.

Medição reproduzível: `tools/profile_morro.gd`. Comparações de tempos entre frames
incluem o limite de FPS e o escalonamento do sistema; contadores de processo do Godot
não foram tratados como decomposição precisa de CPU/GPU.

## Reproduzir

- `node scripts/godot-morro-sync.mjs`
- `godot --headless --path godot --script res://tests/journey_playthrough.gd -- --with-morro`
- `godot --headless --path godot --script res://tests/morro_map_checks.gd`
- `godot --headless --path godot --script res://tests/morro_transaction_checks.gd`
- `godot --path godot --script res://tools/capture_campaign.gd -- --shot=morro-battle`
- `godot --path godot --script res://tools/profile_morro.gd`

Build local: `exports/windows/PipaKlub.exe` e `PipaKlub.pck` juntos.
Steamworks/App ID ainda não existem. Esta entrega não publica o jogo nem conclui
PIP-60; áudio, integração Steam/online opcional, certificação e demais pendências
seguem registradas em MIGRACAO-PIP-60.md.
