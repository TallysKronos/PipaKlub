# E-mails de conta

O jogo pede envios ao Supabase Auth. O provedor SMTP é configurado no projeto Supabase, fora do código; o ambiente existente foi preparado com Brevo. Não há processador próprio de e-mail nem chave SMTP no navegador.

| Mensagem | Origem | Dados | Verificação |
|---|---|---|---|
| Confirmar cadastro | `/account/signup` → `/auth/v1/signup` | E-mail, senha para Auth e apelido de cadastro | Testes do contrato de Auth; entrega real pendente no roteiro |
| Recuperar senha | `/account/recover` → `/auth/v1/recover` | E-mail e retorno ao mesmo domínio do jogo | Limite de 5 pedidos por janela de 15 min no processo; resposta genérica de sucesso |

O jogo não faz reenvio automático de mensagens. Em falha ou limite, mostra o erro e mantém caminho para tentar depois. A entrega e os limites do SMTP são externos; investigar em Auth logs do Supabase e logs transacionais da Brevo. Não copiar links de confirmação/recuperação para relatórios ou issues.

Fluxo de senha segue a [documentação oficial do Supabase](https://supabase.com/docs/guides/auth/passwords). A validação do bearer e a atualização são do provedor; a senha nova é digitada pelo próprio jogador.
