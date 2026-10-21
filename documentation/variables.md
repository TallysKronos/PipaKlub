# Configuração e segredos

Nenhum valor de credencial deve entrar neste documento ou nos artefatos de teste.

| Nome | Uso/escopo | Fonte | Rotação e risco |
|---|---|---|---|
| `SUPABASE_URL` | Servidor: Auth/REST | Variável protegida no Render; exemplo sem dados em `.env.example` | Endereço do projeto; conferir ao migrar ambiente |
| `SUPABASE_PUBLISHABLE_KEY` ou legado `SUPABASE_ANON_KEY` | Servidor: cabeçalho apikey para Auth/REST | Projeto Supabase → configuração do serviço | Não é chave administrativa; troca exige conferir login e RPCs |
| `PIPA_DB_HOST`, `PIPA_DB_PORT`, `PIPA_DB_USER` | Servidor: conexão PostgreSQL restrita | Configuração do pooler e papel `pipa_server` | Usuário deve continuar restrito; host errado pode apontar outro ambiente |
| `PIPA_DB_PASSWORD` | Somente servidor: senha do papel restrito | Campo protegido do Render | Alterar no banco e no serviço em conjunto; nunca imprimir |
| `PIPA_DB_CA` | Servidor: certificado opcional | Certificado do endpoint | Preservar verificação TLS; não resolver erro desativando certificado |
| `CLARITY_ID` | Build/cliente: identificação do projeto de telemetria | Build ou padrão do projeto | Não é segredo; fluxo de privacidade existente precisa ser respeitado |
| `PORT`, `NODE_ENV`, `NODE_VERSION` | Processo/hosting | Render e `render.yaml` | Não são credenciais |
| `LOCAL_TRADE_SLOT`, `LOCAL_TRADE_PORT` | Somente ferramenta local de fixtures | Comando explícito em `scripts/local-trades.mjs` | Nunca usar a autenticação de fixtures em produção |

Não há senha do banco nem chave de serviço Auth embutidas pelo build. O navegador recebe dados de conta autorizados, não o objeto de ambiente. Cookies de sessão são HttpOnly/SameSite; a credencial de sala fica na aba. O bearer de recuperação fica apenas em memória e é descartado ao concluir/cancelar.

Antes da divulgação: conferir serviço apontando ao projeto correto, `Restricted game database verified` no deploy, `/account/config` habilitado, URLs de retorno Auth compatíveis com o endereço oficial e entrega dos e-mails. Arquivos `.env*`, `.local/` e credenciais não entram no commit.
