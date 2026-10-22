# Publicação da Oficina das Almas

## Pacote preparado

- Migrações: `supabase/migrations/024_soul_workshop.sql` e, em seguida, `025_workshop_reveal.sql` (etapa do papel com escavação).
- Código: novo endpoint `/account/workshop`, modelo e renderizador compartilhados, interface de criação no destino existente do clube, assets originais e ambos os builds web.
- Pós-verificação: `verificar.sql`, consulta estrutural sem leitura de contas.
- Prévia local: `http://127.0.0.1:5237/`.
- Guia de entrega, limitações e origem da arte: `art/workshop-v1/README.md`.

## Efeitos da migração

Instala montagens e recibos de confirmação com RLS e sem acesso direto dos clientes. A função de construção usa a identidade autenticada; bloqueia conta diferente, molde incompatível e etapas fora de ordem. Fecha os rituais antigos ainda ativos e devolve suas rabiolas reservadas ao estado pronto. Preserva coleções e histórico. Não altera senhas, não reinicia campanhas e não concede parceiros em massa.

Revoga a função antiga de constelação para clientes autenticados. A função administrativa de concessão de rabiolas continua restrita. A referência da rabiola passa a ser a espécie cadastrada, em vez de depender de haver um feitiço antigo para ela.

O kit básico é fornecido pelo ateliê nesta versão. Não adiciona tabelas de moedas, materiais pagos, bônus competitivos ou alterações de atributos. Novos parceiros só são concedidos no término de uma montagem válida com uma rabiola pertencente à própria conta.

## Ordem de publicação

1. Conferir backup e plano de publicação do ambiente habitual.
2. Aplicar as migrações 024 e 025 autorizadas, nessa ordem, e executar `verificar.sql`.
3. Publicar o servidor e os clientes construídos desta mesma revisão. Durante a troca, clientes antigos devem recarregar: o endpoint antigo retorna 410 explicando a mudança.
4. Validar numa conta de teste: seleção, montagem parcial, recarga, retomada, despertar e coleção. Confirmar que o reenvio não duplica concessões.

Não voltar ao código antigo mantendo rabiolas reservadas em `workshop_jobs`: ele desconhece essas reservas. Em caso de erro, manter a oficina indisponível e preparar uma correção, preservando montagens e coleção.

## Estado e validação

- Banco local isolado: migração aplicada e fluxo concluído.
- Testes: **358 testes passaram** na suíte completa final; builds Worker/servidor e Pages gerados e verificados. Após o ajuste final de cabeçalho, a verificação da oficina foi repetida.
- Navegador: criação de Rabbito, retomada após recarregar e seleção do parceiro na coleção verificadas localmente.
- Arte: bancada original e peças de Rabbito geradas, fontes preservadas, PNG transparente verificado e composição revista no navegador.
- Entrega Git: pacote na branch `feat/pip-58-oficina-das-almas`, incluindo a especificação da [PIP-58](https://linear.app/pipaklub/issue/PIP-58/epico-oficina-das-almas-ferramentas-materiais-bonus-de-fabricacao-e). O protótipo desta branch não implementa ainda toda a evolução descrita na issue.
- Produção: migração 024 e deploy pendentes. Aplicar 024 em produção requer autorização específica, pois a anterior cobria somente 017–023. Integrar na `main` após coordenar essa migração com a publicação do servidor.

## Etapa do papel com escavação (branch `claude/oficina-bancada-jogo`)

- A etapa 3 deixou de ser quatro cliques: a marca da alma do Rabbito fica sob retalhos colados e é revelada com estilete (rápido, rasga onde a marca já aparece) e tesourinha (lenta, quase sem rasgo), com a Luz do molde (2 usos) e 90 s de bancada após uma contagem de 3 s. O tempo pausa com a aba oculta e, ao acabar, a etapa fica com o que foi revelado.
- Rasgo médio de 50% faz a folha ceder. Nesta versão o papel é do kit do ateliê: a falha só pede para recomeçar a folha; a rabiola continua reservada. Quando a economia de materiais existir, a falha consumirá o lote.
- `025_workshop_reveal.sql` troca só a validação da etapa 2: aceita `{"cuts":[0,1,2,3]}` como antes ou `{"cuts":[0,1,2,3],"reveal":N}` e grava N como nota. **A nota ainda é declarada pelo cliente** e só entra na qualidade registrada, sem efeito em combate; antes de qualquer bônus, o servidor deve reproduzir os golpes pela semente da folha.
- A montagem ocupa a tela inteira, com etapas no topo, "Sair da bancada" e o painel de ferramentas ao lado; no celular em pé a câmera aproxima a folha durante a revelação.
- Verificado localmente (conta Ana com `LOCAL_WORKSHOP_FIXTURE=1`): falha por rasgo, recomeço, revelação com nota 90, conclusão com qualidade 98 e o card do despertar; 1280×800, 390×844 e 844×390. Não testado em aparelho físico.
- A prévia `art/workshop-v1/index.html` continua com o recorte antigo por quatro pontos na etapa do papel.
