# Página pública

O jogo entrega o mesmo HTML para pessoas e bots; não há prerender ou roteamento especial para crawlers. `src/index.html` define título e descrição estáticos, sem dados da conta em metadados.

| Rota | Conteúdo público | Limite |
|---|---|---|
| `/` | Shell e artes do jogo | Perfil/inventário só vêm por endpoints autenticados |
| `/?sala=...` | Convite com código público de sala | Nunca colocar a chave privada do jogador na URL |
| `/health` | Estado e identificação `demo-rc.1` | Não diagnostica banco, e-mail ou qualidade da partida |
| `/assets/...` | Allowlist de artes publicadas | Não servir arquivos locais arbitrários |
| Rotas de auditoria | Previews do sistema de UI | Não são área de conta nem painel administrativo |

Links de recuperação podem carregar tokens no fragmento; o cliente os remove antes de apresentar a troca de senha. Não usar esse fragmento em metadados, feedback ou capturas compartilhadas.
