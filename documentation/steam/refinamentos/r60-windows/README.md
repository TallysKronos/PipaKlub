# R60 — primeira prova no executável Windows release

05/11/2026. Base `9951cbac` mais as alterações deste pacote. Engine/templates oficiais Godot 4.7.2 stable.

## Falha real encontrada e corrigida

A prova anterior do exportador chamava `--script`. No template release oficial desta versão, a opção é ignorada: o jogo abria normalmente o título e não executava a sonda. O processo atingiu o timeout de 120 segundos, sem gerar aprovação falsa. O diagnóstico verbose mostrou a cena principal sendo aberta. A documentação oficial distingue [opções disponíveis conforme o tipo de build](https://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html); opções desconhecidas podem ser ignoradas sem aviso.

Foi substituído esse caminho por um dispatcher fixo na entrada da aplicação. Ele só atua com variável `SOULMONSTERS_PACKAGE_PROBE=1` **e** argumento de usuário `--package-probe` com um dos modos `resources`, `create`, `resume`. Não carrega caminhos de script fornecidos pelo usuário. Sem a combinação explícita, o frontend continua normal.

As sondas executáveis passaram a ser `RefCounted` chamadas com a árvore real. O wrapper SceneTree para testes no editor foi preservado. O exportador agora também coleta o log antes de informar timeout.

## Pacote testado

- Templates baixados da distribuição oficial e conferidos por SHA-512; registro em `templates-sha512.txt`.
- Exportação release Windows x86_64 com exe e PCK separados.
- Prova de recursos executada pelo **Soulmonsters.exe exportado**, não pelo editor: 58 checks, zero falhas.
- Manifesto de hashes/tamanho em `build-info.json`. O manifesto informa alterações não commitadas porque foi gerado para validar este lote antes do commit; não representa uma tag RC limpa.
- Binários permanecem nos artefatos locais de teste, fora do repositório.

## Save e mudança de instalação

`ValidarPacote.ps1` verifica os hashes, copia apenas exe/PCK para uma pasta nova com espaços e acentos e usa um diretório de trabalho separado sem projeto. Usa um perfil APPDATA descartável, sem acesso ao save real do jogador.

| Etapa | O que foi comprovado | Resultado |
| --- | --- | --- |
| Criar | Release sem feature editor; cena principal chega ao título, cria slot pela API real, grava nome/moedas/checkpoint e constrói o quarto retomado. | 14 checks, zero falhas. |
| Reiniciar | Novo processo do mesmo exe retoma os dados gravados no perfil isolado e abre o checkpoint. | 12 checks, zero falhas. |
| Mover | Somente a cópia de instalação descartável é movida; outro processo em nova pasta retoma o mesmo save. | 12 checks, zero falhas. |

Total: **38 checks da jornada do pacote + 58 de recursos**. Logs diretos do motor em `create.txt`, `restart.txt`, `relocated.txt`, `resources.txt`; resumo em `package-results.json`.

A movimentação é restrita por verificação de caminho à pasta nova de resultados. O validador não move o pacote fonte, não exclui instalação real e não modifica a pasta de saves do jogador.

## Integração

CI passa a rodar o validador após exportar, com timeout, logs e resultado anexados. Erro de processo, erro de script, recurso inválido, marcador ausente ou hash divergente bloqueia a prova. Os três modos da jornada exigem opt-in e usam um armazenamento de teste separado, mesmo dentro do perfil descartável.

## Limites e estado de R60

**Validado localmente o recorte executável/headless, cena inicial, save/load e instalação movida.** A máquina usada tem ferramentas de desenvolvimento instaladas, embora os testes chamem somente exe/PCK copiados. Isso não certifica uma VM/PC limpo, requisitos mínimos, renderização/controle físico, instalação Steam, desinstalação, nem migração entre versões diferentes. Mover a mesma build não é uma atualização real. Esses casos continuam pendentes.

O resultado integral da CI ainda precisa ser conferido após enviar este lote. Nenhum merge, deploy ou publicação Steam foi feito.
