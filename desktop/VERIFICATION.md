# Prévia desktop 0.1.0 · 18/10/2026

Primeira etapa local da migração, sem dependência de conta Steamworks ou App ID.

- Runtime Electron 44.9.0 e Electron Packager 20.3.0, versões fixadas em `desktop/package-lock.json`.
- Cliente preparado com 216 arquivos instalados, incluindo fontes locais. Telemetria desativada para esta prévia. APIs e WSS usam o backend existente, com perfil do aplicativo separado do navegador.
- 7 testes desktop aprovados: origem HTTPS, navegação, lista de arquivos, traversal, preservação da requisição de conta, modo offline, CSP, geração SteamPipe em preview e conteúdo do bundle.
- Teste de inicialização em desenvolvimento, online: página carregada, 24 requisições locais e serviço de contas disponível. Offline: página carregada e 24 requisições locais, sem operações remotas.
- Executável Windows x64 gerado e testado separadamente com os mesmos resultados online e offline.
- Builds web e Pages e validação ESM aprovados. Os 241 testes existentes passaram. Os testes desktop são executados à parte porque exigem a preparação do bundle.
- Distribuição: `dist/steam/PipaKlub-win32-x64/PipaKlub.exe`, acompanhado dos demais arquivos da pasta. Pasta completa: 73 arquivos, aproximadamente 520 MiB.

Os testes de inicialização não substituem uma partida manual. Login real do proprietário, reinício com sessão persistida, multiplayer entre desktop e web, controle, áudio e jogo completo offline ainda precisam de validação manual. O perfil do navegador não é importado.

Ainda não existem integração nativa Steamworks, conquistas Steam, Steam Cloud, overlay validado, instalador, assinatura Windows ou ícone final. O executável usa o ícone padrão do runtime. Os VDFs só são gerados quando os IDs reais forem fornecidos e começam em `Preview=1`, sem upload automático.

Esta etapa não alterou a implantação de produção nem publicou um jogo na loja. Próxima etapa: teste funcional desta distribuição em Windows e priorização dos defeitos encontrados.
