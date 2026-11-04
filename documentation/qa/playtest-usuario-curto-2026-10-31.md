# Playtest curto pela interface

Teste nativo com mouse e teclado pela ferramenta de Computer Use. Não é execução de testes unitários nem uma vitória simulada.

Para reduzir tempo e custo, foram usados três slots novos isolados: início, retomada após treino e chegada à área da Mikka. Os dois últimos são checkpoints preparados; os quatro desafios anteriores não foram jogados nesta sessão. Não foram usados saves reais nem alterados resultados de combate. O jogo foi aberto pelo executável do Godot com o projeto atual, não por uma build exportada de distribuição. As duas janelas próprias do teste foram encerradas ao final; a janela original do usuário foi preservada.

## Confirmado pela interface

- Menu principal e seleção de jornada funcionam.
- O prólogo inicia o vídeo; **Pular abertura** chega ao quarto e à fala de Kael.
- O botão de pausa do início abre o menu; **Voltar ao menu** preserva o checkpoint.
- A retomada pós-treino apresenta o banner da carteira e chega à orientação do professor.
- As três páginas de orientação avançam por Enter e **Ir à oficina** abre a escolha das quatro rabiolas.
- **Salvar e voltar ao menu** funciona nessa tela.
- A jornada final carrega, o clique movimenta Kael até Mikka e aparece a indicação **E · Conversar com Mikka**.

## Problemas observados

1. **Miniaturas dos saves:** prólogo e pós-treino exibem a arena ao ar livre, apesar de indicarem Prólogo/Ateliê. O nome da localização e a imagem não correspondem.
2. **Identificação do bairro:** a chegada à Mikka e o slot correspondente dizem **Parque dos Ventos**, embora ela seja a campeã do Morro do Sol. Isso enfraquece a orientação do campeonato.
3. **Balão de aproximação:** o texto inicial da Mikka ocupa uma caixa alta sobre o ponto de interação e encobre Kael/Mikka. Precisa de posicionamento ou texto mais compacto.

## Limitação de entrada verificada

E e Enter não abriram a conversa no mapa através da automação. Para não atribuir isso incorretamente ao jogo, uma janela Godot separada, sem gameplay, registrou os eventos enviados pela mesma ferramenta:

`E → logical=69, physical=4194313`.

O jogo usa bindings físicos; o evento automatizado não representa a tecla física E. Portanto, este teste **não conclui que o teclado do jogador esteja quebrado**. Também não valida manualmente o combate contra Mikka, sua dificuldade ou a entrega da insígnia. Essa última continua coberta pelas verificações de integração anteriores, que usam estados terminais de teste.

Conclusão: início e transição dos documentos para a oficina funcionam na interface; há os três ajustes visuais acima. Não houve validação humana ponta a ponta nem teste do executável exportado. Nenhum problema de gameplay foi corrigido nesta sessão de auditoria.
