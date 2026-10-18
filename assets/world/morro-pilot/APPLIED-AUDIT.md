# Auditoria da aplicação do kit — 18/10/2026

Escopo: piloto opcional da chegada do Zeca até o patamar da Bia, com conta Cora do banco local isolado. Não houve acesso a dados de produção nem publicação.

## Corrigido durante a auditoria

1. As folhas estavam copiadas nos builds, mas faltavam na lista explícita do servidor de assets. Incluídas com teste de HEAD/cache e rejeição de arquivos não autorizados.
2. Telhados inicialmente flutuavam acima das fachadas. Apoios ajustados na composição, preservando proporções dos recortes.
3. Caminhos tinham transição retangular abrupta para a grama. Adicionada borda de pedra nas extremidades externas da união do chão; conexões permanecem abertas.
4. Luminária decorativa ficava no chão acessível sem base física. Criado sólido correspondente; clique no apoio agora mostra bloqueio.
5. Sair de duelo removia a opção do piloto da URL. O fluxo de saída preserva essa opção quando o piloto está ativo.
6. Chão com muitos ladrilhos seria recomposto a cada quadro. Cache em OffscreenCanvas após carregar as folhas.

## Verificado

- Chegada: fachada/telhado, copa/tronco, muros, cerca e objetos sem quadriculado embutido ou partes de outros frames.
- Escada e patamar: percurso completo com Kael e parceiro, cobertura do piso inferior não esconde os atores do piso superior.
- Luminária e casas: colisão permanece separada da altura visual.
- Zeca: aproximação, abertura da preparação, entrada num duelo local, pausa e saída retornando ao mesmo encontro. Esse teste encerrou uma partida de demonstração, sem conceder recompensa.
- Após a correção, repetida a entrada/saída de duelo: confirmado retorno ao encontro com `?overworld=pilot` preservado. Nenhum erro de console nessa rodada final.
- Bia: caminhar até o local não libera o duelo; bloqueio da progressão confirmado no navegador.
- Builds servidor/Pages e validação ESM passaram. Suíte completa antes do ajuste final da URL: 226/226. Testes específicos cobrem recortes, proporções, bindings, base da luminária, colisão, conexão de pisos e assets servidos.
- MCP validou a estrutura Tiled sem erros/avisos.

## Pendências e limites

- PIP-41: rivais ainda usam as ilustrações atuais, com proporções diferentes do Kael chibi. Não considerar a composição de personagens finalizada.
- PIP-42: refinar vegetação de transição e a composição do bairro; os caminhos continuam seguindo o traçado ortogonal do piloto.
- O painel inferior e os atalhos ocupam espaço significativo na janela desktop pequena usada na inspeção. A redução do painel está relacionada à PIP-30.
- Esta rodada não conclui a expansão ao Morro inteiro/Quintal e não certifica uso em controle/Steam. Nenhum merge/deploy foi feito.

Arquivos de autoria: `blockout.tmj` (geometria), `art.json` (apoios/peças), `morro-kit-v1/manifest.json` (fontes dos recortes). O Tiled não exibe automaticamente esta composição de atlas: o plano é interpretado pelo jogo; uma prévia visual dentro do editor requer extensão/exportação própria.
