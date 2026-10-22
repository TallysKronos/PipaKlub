# Publicação da Oficina das Almas

## Pacote preparado

- Migração: `supabase/migrations/024_soul_workshop.sql`.
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
2. Aplicar a migração 024 autorizada e executar `verificar.sql`.
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
