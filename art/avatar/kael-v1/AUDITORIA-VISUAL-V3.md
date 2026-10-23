# Auditoria visual v3 — 23/10/2026

Escopo observado: prévia local em http://127.0.0.1:5248/, renderizador da sala/quarto e avatar. Foram reproduzidos caminhar até o sofá, sentar, levantar com destino à escada, subir, descer e alterar pele/cabelo/jaqueta. A largura da janela variou durante a inspeção, incluindo aproximadamente 810 e 302 pixels. Esta revisão não certifica o fluxo autenticado do jogo, outros mapas, produção ou persistência no servidor. Nenhum asset ou código de produto foi alterado nesta auditoria.

## Achados por prioridade

1. **Alta — desembarque da troca de cômodo na prévia.** Ao subir, Kael aparece junto à peseira da cama; ao descer, reaparece no centro da sala, afastado da base da escada. Isso quebra a continuidade espacial, apesar de cada animação isolada funcionar. O harness `tools/avatar-studio/game-review.mjs` recria o ator em `room()` e força a posição (1000,1000) na sala. Usar desembarques específicos por sentido e conferir separadamente os consumidores reais; a observação aqui não prova o mesmo defeito em produção.

2. **Média — linguagens de acabamento misturadas.** Sofá e mesas têm planos amplos e chapados, enquanto parede, piso e escada mantêm textura e contornos mais irregulares. A cama também fica visualmente mais limpa que a estante ao lado. A paleta comum ajuda, mas não resolve densidade de detalhe e acabamento. Unificar espessura de contorno, quantidade de tons e textura, preservando a direção 2D minimalista aprovada.

3. **Média — passada ainda pouco convincente.** O deslocamento ocorre sem braços soltos, mas as poses amostradas continuam com pernas compactas e solado muito exposto em parte do ciclo. A sincronização por distância não substitui contato, passagem e apoio alternado bem desenhados. Revisar esses desenhos em câmera lenta, com os pés sobre uma guia de chão. A inspeção não mediu deslizamento em pixels nem certificou alternância anatômica perfeita. Os três avisos de altura do relatório técnico anterior continuam sendo uma pendência, não um novo teste executado nesta auditoria.

4. **Média — leitura de contato no sofá.** O personagem já se lê sentado, mas fica muito na borda frontal e com o tronco distante do encosto. A almofada não reage e o conjunto parece uma pose sobreposta. Ajustar profundidade de quadril, oclusão pelo assento e sombra de contato; uma pequena resposta da almofada pode vir depois. É refinamento visual, não falha de acionamento.

5. **Média — valores escuros perdem separação.** Na combinação pele Escuro + cabelo Preto + jaqueta Verde-mata, rosto, cabelo e torso ficam menos distinguíveis na miniatura. As cores são aplicadas e o rosto continua reconhecível, porém os meios-tons poderiam separar melhor os volumes. Ajustar rampas de sombra e luz mantendo o tom de pele selecionado; não clarear a pele como solução. A aparência inicial Mel/Azul-noite/Azul foi restaurada ao concluir.

6. **Média, restrita à ferramenta — prévia estreita reduz demais o cenário.** Com cerca de 302 px de largura, toda a sala cabe em uma pequena miniatura; avaliar pés, expressões e colisões torna-se inviável. Os selects em duas colunas também truncam nomes como Verde-mata. Oferecer zoom/pan ou modo de inspeção e uma coluna para campos nessa largura. Não extrapolar esse achado para a interface mobile do jogo, que não foi aberta.

7. **Baixa — identidade narrativa ainda discreta.** As cores e formas já são coerentes com uma casa acolhedora, mas faltam objetos que contem a relação do protagonista com as pipas. Há desenho de molde e esboços no quarto, porém a sala é genérica. Acrescentar poucos elementos significativos — carretel, pipa em construção ou foto — depois de resolver contato, desembarque e acabamento.

## Melhorias confirmadas

- A descida desaparece progressivamente dentro da abertura e não caminha para o fundo vazio.
- A cama permanece sólida durante a descida observada.
- O percurso até o sofá e a saída para a escada ocorreram sem teleporte entre piso e assento.
- A pose sentada é mais legível que o agachamento anterior.
- Não observei o antigo braço destacado nas sequências reproduzidas.
- As cores alternativas se aplicaram às quatro vistas da prévia.

## Evidências locais

Capturas em `.local/auditoria-visual-v3/`: `chegada-quarto.png`, `descida-600.png`, `descida-2000.png`, `descida-3400.png`, `descida-4800.png` e `aparencia-estreita.png`. A pasta é local e não integra o pacote de assets. Não foram repetidos testes automatizados: esta foi uma inspeção visual e de interação.

Ordem recomendada: desembarques e espaço livre junto à cama; poses da caminhada e contatos; unidade de acabamento; rampas alternativas; melhorias da bancada e detalhes narrativos. O conjunto evoluiu, mas ainda não recebe aprovação artística final nesta auditoria.
