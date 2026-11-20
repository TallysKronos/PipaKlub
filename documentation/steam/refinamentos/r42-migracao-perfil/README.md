# R42 — migração do save e proteção contra duas janelas

O formato suportado `schemaVersion: 1`, `contentVersion: demo-1` e `rulesVersion: demo-1` continua abrindo sem gravar. A leitura converte o XP para a curva atual; na primeira gravação, o backup rotativo guarda o conteúdo anterior com as regras antigas. Se o primário faltar ou estiver danificado e o backup for válido, a próxima gravação preserva esse backup. Formatos desconhecidos continuam bloqueados.

A matriz usa quatro saves reconstruídos no formato antigo: introdução, Bambuzal, Câmara do Elo e estádio. Compara o snapshot inteiro após a migração, exige que abrir não altere o arquivo, verifica que o XP não seja convertido novamente e simula a perda do primário para recuperar o backup. As fixtures não são saves históricos de jogadores nem um playtest dos quatro trechos.

A cena principal reclama a exclusividade do perfil antes de carregar preferências ou abrir a campanha. Uma segunda janela com o mesmo perfil recebe aviso e encerra. O sistema operacional libera a reserva ao terminar o processo, inclusive no encerramento abrupto. O gate de Windows inicia um dono, tenta abrir a cena principal em outro processo e confirma que o perfil pode ser aberto novamente depois de matar o dono.

A exclusividade usa uma porta TCP no loopback derivada do caminho do perfil, sem aceitar conexões ou trocar dados. Uma porta ocupada por outro programa ou uma colisão de portas entre perfis bloqueia a abertura de forma conservadora. A proteção vale para a cena principal: scripts de manutenção e versões antigas que não a usam não cooperam. Não certifica caminhos equivalentes por links/junções, perfis Steam distintos, Cloud, outros sistemas operacionais ou falhas físicas de disco/energia.

Com a importação Godot preparada, o teste isolado da exclusividade pode ser repetido com PowerShell 7:

```powershell
./godot/ValidarInterrupcoes.ps1 -GodotPath 'C:/caminho/Godot_v4.7.2-stable_win64_console.exe' -ProfileOnly
```
