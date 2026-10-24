# Oficina das Almas · protótipo v3

Protótipo de jogabilidade para testar a proposta "fácil de entender, difícil de dominar, risco por escolha" antes de mudar a bancada do jogo. Rode `npm run oficina:v3` e abra http://127.0.0.1:5243/. Não usa conta, banco nem servidor do jogo.

## Como se joga

Cada etapa é um minijogo de um gesto, de 10 a 20 segundos. A ferramenta certa aparece sozinha na mão. A instrução fica no balão sobre a mesa, com a contagem. O Sr. Assis explica cada etapa na primeira vez, e uma mão fantasma mostra o gesto depois de 4 s parado.

| Etapa | Gesto | Erro custa |
|---|---|---|
| 1. Armação | Arrastar a vareta do leque até o círculo. Na Incomum e na Rara ela balança: soltar quando brilhar alinhada. | Nada (volta para o leque), só nota menor |
| 2. Nós | Segurar o nó; o anel enche cada vez mais rápido; soltar no verde | Soltar no vermelho arrebenta: −1 linha |
| 3. Papel | Recortar pelo pontilhado; cola e encaixe são automáticos | Entrar na vela enche o medidor de rasgo; cheio = −1 folha |
| 4. Voo | 9 s de vento. A rajada é avisada antes (seta); arrastar o cabresto para o lado contrário | Deixar a pipa passar de 46° = cai: −1 linha |
| 5. Despertar | Segurar; a barra sobe acelerando | Soltar em **Seguro** garante. **Brilho** dá chance de variante rara (25 % + 10 % por estrela acima de 1, até 65 %). Passar para **Excesso** parte o elo e a rabiola fica danificada |

Materiais visíveis no topo: 3 carretéis de linha e 2 folhas. Sem material a montagem para; aqui um botão simula buscar mais na exploração. A nota de cada etapa (Perfeito, Bom, Ok) vira de 1 a 5 estrelas.

**Classes:** Comum (4 varetas), Incomum (5) e Rara (6) mudam a janela do anel, a tolerância do corte, o balanço da vareta e a força do vento, e não a quantidade de repetições. **Modo artesão** esconde as guias (círculos, faixas do anel, pontilhado) e soma bônus de nota em cada etapa.

Teclado: Espaço encaixa a próxima vareta, segura o nó e segura o despertar; setas controlam o cabresto.

## Calibragem do vento

Simulação de 20 voos por classe:

| Classe | Parado | Endireitando a pipa |
|---|---|---|
| Comum | 50 % | 100 % |
| Incomum | 39 % | 100 % |
| Rara | 36 % | 77 % (precisa antecipar as rajadas) |

## Arquivos

`model.mjs` tem todas as regras, sem DOM, com o tempo passado de fora. Isso permite que o servidor do jogo reproduza a mesma partida para validar a nota (pendente na bancada atual). `model.test.mjs` cobre as cinco etapas, as perdas de material e o despertar. `game.mjs` cuida do desenho e da entrada. `mesa.jpg` é uma cópia reduzida de `assets/workshop/v2/bench.png`; `rabbito.png` é um recorte de `assets/creatures/overworld-v1/rabbito.png`. A variante rara é só um filtro de cor no protótipo.
