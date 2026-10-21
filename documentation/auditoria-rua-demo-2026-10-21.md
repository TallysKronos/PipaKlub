# Auditoria da Rua dos Ventos e entrada da demo

Data: 21/10/2026. Base: `ed3432e`, integrada à `main` local. Destino de identidade definido pelo projeto: **Soulmonsters Chronicles: Fios do Destino**.

## Ambiente e escopo

Teste no navegador integrado, viewport observado de 1280 × 720, servidor local na porta 5225 e PostgreSQL/PGlite persistente em `.local/street-audit-2026-10-21`. Conta fictícia Kael Local, inicialmente sem abertura concluída. Autenticação simulada pelo adaptador local existente, com APIs reais do jogo. Nenhum acesso ao banco de produção, alteração da conta do proprietário, push ou deploy nesta rodada.

## Jornada percorrida no navegador

1. Transmissão da final regional e exploração do quarto.
2. Caminhada até a mesa, montagem do Rabbito, conversa com a mãe e recebimento da Rabiola Antiga.
3. Manifestação e nomeação do parceiro, caminhada à escada e saída da sala.
4. Chegada à Rua dos Ventos com Rabbito equipado. Entrada na casa do professor e retorno pela porta.
5. Travessia da rua até a casa de Kael, subida ao quarto, descida à sala e saída. Entrada na loja e inspeção do interior.
6. Retorno ao professor e conclusão dos cinco exercícios, sem pular: movimento, ataque no cruzamento, recuperação de energia, habilidade do parceiro/esquiva/rebicada e corte de Nozinho.
7. Abertura do mapa da cidade e entrada no Morro do Sol pelo fluxo padrão.
8. Caminhada até Zeca, apresentação do encontro, duelo de duas rodadas e derrota. A interface confirmou resultado salvo e 20 XP para o parceiro; retorno ao bairro manteve Rabbito e a posição de Kael. Os encontros seguintes continuaram bloqueados.
9. Após reiniciar o servidor e reautenticar a conta fictícia, abertura e primeiro voo continuaram concluídos.

O teste não equivale a uma campanha inteira vencida. A derrota foi útil para conferir retorno e ausência de desbloqueio indevido. Não houve vitória manual nos cinco encontros nesta rodada.

## Correções

### Bloco marrom sobre a escada

O objeto `Vaso ao lado da escada`, em `assets/world/street-v1/kael-home.tmj`, era sólido e também pintado pelo renderizador de blockout sobre o fundo ilustrado. A propriedade `hidden` agora oculta sua representação auxiliar e preserva a colisão. Um teste verifica simultaneamente a recusa de caminhar pelo vaso e a ausência de chamadas de desenho desse objeto.

### Objetivo desatualizado após a batalha

Ao retornar ao Morro na mesma posição, o objetivo podia mostrar “Encontre Zeca” em vez de “Converse com Zeca”. O cache de contexto permanecia válido enquanto a identidade reconstruía o texto sem a proximidade restaurada. `openWorld` agora invalida a chave da missão antes de reconstruir a cena. A regressão adicionada em `first-flight.test.mjs` falhou antes da correção e passou depois.

### Instruções de navegação antigas

As saídas da abertura agora dizem “rua”/“Rua dos Ventos”. O último botão do primeiro voo diz “Voltar ao professor”, correspondente ao local efetivo de retorno. O diálogo seguinte orienta seguir pela rua. Os destinos de saída do Morro, incluindo os estudos alternativos, passaram a indicar a Rua dos Ventos. Os identificadores internos `quintal` continuam válidos para preservar contratos e progresso.

## Verificações técnicas

- 111 pares de destinos nos cinco mapas novos: rua, sala, quarto, loja e casa do professor. Cada percurso foi executado pelo navegador de caminhos, conferindo chegada e segurança geométrica dos pés de Kael e do seguidor a cada passo.
- Teste da UI confirma que concluir uma lição salva seu checkpoint e avança a mesma execução do primeiro voo.
- Suíte completa final: **295 testes aprovados, nenhuma falha**, após a correção do objetivo. Execução registrada em `tmp/street-audit-tests-final.log`.
- Após os ajustes dos textos, builds Worker e Pages concluídos, artefato ESM válido e 37 testes direcionados aprovados. A regressão específica do objetivo também foi executada após a correção.
- Evidências visuais em `art/ui-reviews/street-audit-2026-10-21/`.

## Pendências para a candidata da demo

1. **Morro novo — integração local concluída após esta auditoria.** O percurso de cinco áreas passou a ser o padrão após autorização do responsável. Ver comportamento, evidências e limites em [Integração do Morro](integracao-morro-demo-2026-10-21.md). A publicação e o playtest completo de vitórias em produção continuam pendentes.
2. **Continuidade dos interiores.** A abertura usa os fundos narrativos de `story/kael-birthday-v1`, enquanto revisitar a casa usa `world/street-v1`. Os cômodos preservam a disposição geral, mas a escada/porta e a composição mudam. Unificar arte, coordenadas dos atores e hotspots em uma etapa própria; trocar só o PNG quebraria a encenação.
3. **Orientação espacial.** As casas têm marcadores discretos e nomes no seletor/contexto, mas faltam placas próprias na fachada. A missão permite atalho direto ao professor. Avaliar isso com jogadores novos antes de exigir caminhada obrigatória.
4. **Identidade.** A nova marca e a start screen ainda não foram aplicadas ao jogo nesta rodada. O título aprovado deve orientar essa produção, incluindo logo e arte separados do menu.
5. **Teste externo.** Faltam celular real, controle físico, dois aparelhos/redes independentes, desempenho em máquina modesta e jogadores sem orientação. A emulação geométrica/câmera dos testes não substitui esses dispositivos.
6. **Produção.** Validar no Render somente após publicar uma candidata; os resultados locais não comprovam disponibilidade de serviços ou recompensas no Supabase real.

## Particularidades do ambiente de teste

A primeira sessão local perdeu autenticação durante a revisão. Havia outras abas de servidores locais abertas em `127.0.0.1`; cookies não são separados por porta. Ao passar o teste para `localhost`, o avanço de checkpoints funcionou e o tutorial foi concluído. A interferência entre ambientes é a hipótese sustentada por essa repetição; não foi feita uma alteração na autenticação de produção para contorná-la. Reiniciar o adaptador local também exige reentrada, pois seus tokens fictícios ficam em memória.

A primeira execução da suíte dentro do sandbox encontrou `EACCES` nos sockets locais. A execução com acesso autorizado a sockets locais passou. Não tratar essas falhas de permissão como defeitos de combate/rede do jogo.
