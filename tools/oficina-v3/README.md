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
| 5. Despertar | Segurar; a barra sobe acelerando | Soltar em **Seguro** garante. A variante rara tem chance fixa de **1 em 459 por nascimento**, independente de nota, classe e faixa de sucesso. **Elo firme** não aumenta essa chance. Passar para **Excesso** parte o elo e a rabiola fica danificada |

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

## Revisão de identidade visual · 23/10/2026

A apresentação usa a paleta de papel, verde, bambu, dourado e coral de Soulmonsters: Elo das Ruínas. As etapas são marcadores de oficina; materiais têm ícones próprios; instruções ficam em um bilhete sobre a mesa. Mão, carretel, tesoura, cabresto e alma mantêm os mesmos pontos de interação, com desenhos próprios. As dobras do papel diferenciam painéis sem revelar a espécie.

`look.mjs` e `style.css` concentram a apresentação. Os botões reutilizam o HUD aprovado de `assets/ui/hud-papel-bambu-v1`, carregado por rotas locais explícitas. As pontas dos botões escalam pela altura definida do controle. `assis.png` é um recorte sem redimensionamento do quadro `speaking` do atlas aprovado `assets/characters/sr-assis/expressions.png`, retângulo absoluto x=410, y=81, largura=322, altura=383.

Na primeira revisão visual, `model.mjs` foi preservado. Na revisão de interação abaixo, as regras dos nós e da variante foram atualizadas. O molde preto do recorte teve sua opacidade corrigida; o mostrador de voo foi afastado do bilhete. O protótipo continua separado da bancada publicada e usa materiais simulados. Não está integrado ao banco nem ao Render.

Validação: `node --test tools/oficina-v3/model.test.mjs tools/oficina-v3/server.test.mjs` passa 9/9 testes, cobrindo as cinco regras, custos, classes, despertar e carregamento seguro dos assets. No navegador foram percorridas as telas de armação, nós, recorte, voo e despertar; encaixe por arraste, montagem por teclado, nós e recorte foram exercitados. O nascimento pelo gesto ainda precisa de conferência em uma aba ativa: a automação em segundo plano não reproduziu o tempo de sustentação. Os testes do modelo cobrem seus resultados, sem substituir essa conferência visual.

Layouts conferidos em 1280×720 e em iframes de 390×844 / 844×390, sem overflow interno. São emulações de layout, não testes em aparelhos físicos. Capturas em `art/workshop-v3/`. As rotas locais `/mobile` e `/landscape` permitem repetir essa revisão.

## Arquivos

`model.mjs` tem todas as regras, sem DOM, com o tempo passado de fora. Isso permite que o servidor do jogo reproduza a mesma partida para validar a nota (pendente na bancada atual). `model.test.mjs` cobre as cinco etapas, as perdas de material e o despertar. `game.mjs` cuida do desenho e da entrada. `mesa.jpg` é uma cópia reduzida de `assets/workshop/v2/bench.png`; `rabbito.png` é um recorte de `assets/creatures/overworld-v1/rabbito.png`. A variante rara é só um filtro de cor no protótipo.

## Revisão de interação · mão, tesoura e surpresa rara

A armação usa a mãozinha. A tesoura tem duas lâminas metálicas, parafuso central e dois cabos vazados em coral; abre e fecha durante o corte. A ponta direita coincide com o ponto de corte do cursor.

Os nós sorteiam faixas de 16%, 12% e 9% da circunferência nas classes Comum, Incomum e Rara. O sorteio é feito antes do gesto; a faixa permanece fixa enquanto se segura e muda quando a tentativa falha. O modo artesão continua escondendo as guias. A mesma semente e as mesmas entradas reproduzem a partida para validação futura.

A variante tem probabilidade independente de 1/459 (aproximadamente 0,218%) em qualquer nascimento bem-sucedido. Não é um contador de garantia. O sorteio é separado dos nós e reservado uma vez por montagem: soltar cedo, repetir o gesto, aumentar a qualidade ou esperar o antigo Brilho não permite sortear novamente. O excesso continua partindo o elo. Este protótipo local ainda usa filtro de cor para representar a variante; a arte física e a decisão autoritativa no servidor precisam da integração futura.

Verificação atualizada: 11/11 testes de modelo e servidor, incluindo variação e estabilidade da faixa, repetição de tentativas sem novo sorteio e independência da variante em relação a classe, estrelas e gesto.

Revisão das ferramentas: abra /tools.html para inspecionar os mesmos desenhos da bancada ampliados. Capturas atuais: art/workshop-v3/review-tools-v2.png e review-knots-v2.png. Mão, tesoura e posições diferentes das faixas foram conferidas no navegador; o gesto completo de nascimento continua com a limitação de auditoria registrada acima.

## Pegada animada e bônus de criação

A luva 2D em `hand.mjs` é desenho original: palma, quatro dedos, polegar e punho. Os dedos se recolhem em aproximadamente 140 ms ao segurar uma vareta, e reabrem ao soltar ou cancelar. O fechamento só é acionado por uma vareta realmente agarrada, não por clicar no vazio. O laboratório /tools.html mostra a transição e uma pegada fechada com a vareta.

O protótipo agora calcula um modificador de atributos em `outcome.craftBonus`, apresentado no nascimento. Não havia bônus de atributos na v3 anterior, apenas estrelas. `applyCraftBonus(baseStats, outcome)` aplica esse modificador sem alterar os atributos base. Essa função está testada, mas a v3 continua local: nenhum atributo da coleção ou combate publicado foi alterado. A aplicação autoritativa no servidor e a persistência ainda pertencem à integração futura.

Balanceamento inicial: até +8% por montagem e +4% por Elo firme, total máximo +12%. A qualidade é 75% da média das notas técnicas e 25% da eficiência de tempo, descontando 2,5 pontos percentuais por erro (limite de 40). Erros incluem encaixes falhos, nós frouxos/rompidos, papel perdido e quedas. O tempo começa no primeiro gesto de cada etapa, preserva o histórico ao refazer e exclui dicas, bloqueio por material e aba oculta. Alvos de eficiência: 3 segundos por vareta, 2,2 segundos por nó, 14/12/10 segundos para papel Comum/Incomum/Raro. Voo não tem bônus por encurtar seus 9 segundos obrigatórios. As estrelas agora refletem essa qualidade total.

Despertar: Seguro de 40% a menos de 86%; Elo firme de 86% a menos de 92%; Excesso a partir de 92%. O preenchimento acelerado usa integração analítica para manter o mesmo resultado em 30, 60 e 120 fps. A faixa firme dura aproximadamente 109 ms na Comum, 91 ms na Incomum e 78 ms na Rara; acertá-la adiciona +4%. O Seguro mantém o bônus de montagem. Quebrar o elo não produz Soulmonster nem bônus. A variante rara permanece independente (1/459 por nascimento).

Validação desta revisão: 14/14 testes de modelo/servidor, incluindo cálculo de bônus, aplicação em atributos, relógio, preservação de erros, limites do Elo e equivalência temporal entre taxas de atualização. As poses da mão e sua transição foram inspecionadas no laboratório do navegador; screenshot em art/workshop-v3/review-hand-grip.png. O teste humano completo de reflexo, resultado e integração à coleção continua necessário antes da publicação.

Auditoria adicional concluída no navegador (811×884): encaixe por arraste, demais varetas por teclado, quatro nós em faixas distintas, recorte completo, voo e nascimento. O resultado real exibiu 46,4 segundos ativos, zero erros, montagem +6,4%, Elo firme +4% e total +10,4%. Captura em art/workshop-v3/review-birth-bonus.png. Isso substitui a pendência anterior de conseguir concluir o nascimento na automação; a calibração humana de dificuldade e a integração com a coleção continuam pendentes. Não houve mensagens de erro no console dessa partida.

## Integração de produção — revisão final

As pendências de integração descritas nas revisões históricas acima foram concluídas nesta entrega: a Oficina principal usa checkpoints autenticados, replay no servidor, confirmação atômica do nascimento e bônus persistidos na coleção e no combate. A variante é sorteada no banco (1/459), sem exposição antes do nascimento. O tratamento visual continua por cor; anatomias alternativas por espécie permanecem trabalho de arte separado.

Auditoria no jogo integrado: montagem retomada após reiniciar o servidor local; todas as cinco etapas concluídas; Rabbito concedido uma única vez com +6,8% e bônus exibido na ficha. Evidência: `art/workshop-v3/review-integrated-birth.png`. Os 43 testes direcionados finais passaram, incluindo preservação de montagem antiga e parceiros existentes. Consulte `documentation/publicacao-oficina/V3.md` para publicação e limitações.
