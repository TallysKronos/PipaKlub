# PipaKlub desktop · primeira etapa da migração Steam

Prévia Windows x64 independente de conta Steamworks. O executável inclui HTML, simulação, imagens e fontes. Contas, inventário, progressão confirmada e multiplayer continuam no servidor HTTPS atual. Nenhum banco de produção ou credencial privada é empacotado.

## Instalar e executar

Na raiz do repositório, com Node.js 24 e dependências do jogo instaladas:

```sh
npm run desktop:install
npm run desktop:dev
```

O segundo comando prepara o cliente e abre o jogo. F11 ou Alt+Enter alternam tela cheia. Alt revela o menu desktop, que também oferece escala da interface. O tamanho da janela é salvo. Cookies e armazenamento pertencem a um perfil próprio do aplicativo; usar o mesmo login do jogo, sem esperar que a sessão do navegador seja importada.

```sh
npm run desktop:prepare
npm run desktop:test
npm run desktop:smoke
npm run desktop:smoke:offline
npm run desktop:package
npm run desktop:smoke:packaged
npm run desktop:smoke:packaged -- --offline
```

A pasta de distribuição é `dist/steam/PipaKlub-win32-x64/`. Executar `PipaKlub.exe` e manter os demais arquivos juntos. Esta pasta é o conteúdo de um futuro depot Steam; não é um instalador. O empacotamento é feito por `@electron/packager`, com dependências e runtime fixados no lockfile separado de `desktop/`.

O treino local usa o mesmo código da versão web. O teste automático offline confirma que a página e seus recursos carregam sem servidor; antes de distribuir, testar manualmente uma partida inteira com bots, áudio, controles e retorno ao menu. RPG, conta, itens e partidas online exigem o backend. O servidor gratuito atual continua com suas limitações de disponibilidade; o executável não reduz a latência do servidor.

## Arquitetura

- `build.mjs --desktop`: compila só o cliente instalado, sem alterar Worker, Pages ou configuração da produção. Telemetria desativada nesta prévia.
- `scripts/prepare.mjs`: inclui fontes e licenças locais e gera uma lista explícita dos arquivos servidos. A preparação limpa somente sua pasta gerada.
- `main.cjs`: janela Electron isolada, sandbox, sem integração Node no renderer e sem bridge/IPC privilegiado. Nenhuma URL remota recebe acesso ao filesystem.
- `policy.cjs`: serve a página e os assets instalados no mesmo endereço lógico HTTPS do backend. APIs mantêm Request e Origin e são encaminhadas pela mesma sessão Chromium, preservando cookies HttpOnly/Secure e verificações de origem. O WebSocket usa diretamente WSS no servidor atual. Não há proxy HTTP exposto na rede local, CORS aberto, reescrita de cookies ou desativação de TLS.
- A página recebe CSP com hash do script compilado. Arquivos desconhecidos e navegação para outras páginas são bloqueados; links externos aprovados abrem no navegador padrão. Fontes não precisam de Google Fonts em tempo de execução.
- Perfil do aplicativo: diretório `userData` do Electron. Testes de inicialização usam perfil temporário separado e janela oculta.

O conteúdo instalado conserva sua versão até que se instale outro build. Atualizações web do servidor precisam continuar compatíveis com o cliente; versionar o contrato das APIs e uma versão mínima suportada antes do lançamento comercial. Atualizações do executável serão entregues pela Steam quando essa integração existir.

## Próximas etapas antes da Steam

1. Testar este build em outro Windows, com teclado/mouse e controle. Validar login normal, reconexão, dupla entre desktop e web, partida completa, reinício e persistência de sessão.
2. Auditar progressão, balanceamento, responsividade, erros e tempo de carregamento. Definir requisitos mínimos com medições reais.
3. Preparar ícone final, tela de inicialização, metadados de versão, assinatura Windows e distribuição de testes. O protótipo usa o ícone padrão do runtime e não possui assinatura de código.
4. Separar adequadamente saves locais sincronizáveis de cookies e credenciais. Nunca configurar Steam Cloud para sincronizar todo o perfil Chromium.
5. Só depois de o jogo estar maduro: conta Steamworks, App ID e Depot ID, SDK, lançamento e página da loja.
6. Implementar login Steam com ticket verificado no servidor e vínculo explícito à conta existente. Não confiar em SteamID enviado pelo cliente nem criar/vincular contas por coincidência de e-mail.
7. Integrar e testar overlay, Steam Input, conquistas e Cloud. O controle existente usa Gamepad API; ainda não há integração nativa Steam Input ou certificação Steam Deck.

## SteamPipe preparado para a etapa futura

Após obter os IDs reais, gerar os VDFs sem usar um App ID emprestado:

```sh
npm run steam:config -- SEU_APP_ID SEU_DEPOT_ID
```

Substituir os nomes pelos números reais antes de executar. O gerador rejeita nomes de exemplo e grava `dist/steam/vdf/`. Os arquivos começam com `Preview=1`, sem `SetLive`; nenhum upload é executado por este repositório. No Steamworks, o alvo de lançamento Windows será `PipaKlub.exe`, relativo à raiz do depot. Login Steam e os arquivos do SDK não estão presentes nesta prévia.

Fontes técnicas: [Electron security](https://www.electronjs.org/docs/latest/tutorial/security), [protocol](https://www.electronjs.org/docs/latest/api/protocol), [session fetch](https://www.electronjs.org/docs/latest/api/session), [SteamPipe](https://partner.steamgames.com/doc/sdk/uploading), [Steam authentication](https://partner.steamgames.com/doc/features/auth), [onboarding Steamworks](https://partner.steamgames.com/steamdirect/).
