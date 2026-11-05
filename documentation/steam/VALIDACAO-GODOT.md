# Validação do PR — produto Godot

Atualizado em 05/11/2026. O produto ativo é exclusivamente a campanha Godot. A versão web e seus conversores de mapa não são critérios de aceite do jogo atual.

## Verificação automática

`.github/workflows/godot.yml` substitui o antigo workflow `Demo validation`:

1. Baixa Godot **4.7.2 stable** e templates correspondentes da distribuição oficial, verificando SHA-512.
2. Prepara a importação inicial e exige uma segunda passagem sem erros em `godot/Validar.ps1`, em Windows. Na primeira abertura sem cache, o tema pode tentar resolver fontes/imagens antes de serem importadas; o log inicial é preservado como diagnóstico não bloqueante apenas se o processo encerrar normalmente. Erros que persistam na segunda passagem bloqueiam a execução.
3. Executa 25 suítes de regressão: overworld, Morro, campanha/saves, controles, história final, encenação, viagens release, avisos após load, nomes, flor, recuperação da cidade, reunião, apresentação/libertação Trovareta, fluxo Beira-Canal, menu do título, ciclos de vida do menu, resiliência dos saves, feedback visual/controle de recuperação e erro, recuperação de falha do autosave durante exploração, separação/configuração de autosave e saves manuais, exclusão/reinício de campanha, banco/depósito do perfil, recompensas reservadas e acolhimento de Retalho.
4. Verifica também os recursos importados do título, casa, loja e previews, e gera a exportação Windows release por `godot/Exportar.ps1`. O exportador rejeita erros no log mesmo com retorno zero e executa a mesma sonda de recursos no executável/PCK entregue, fora da pasta fonte, com perfil temporário isolado.
5. `godot/ValidarPacote.ps1` confere hashes, copia somente exe/PCK a uma pasta com espaços/acentos e executa três processos: criar campanha de teste, retomar e retomar após mover a instalação. Todos usam o mesmo perfil descartável e um diretório de trabalho sem projeto.
6. Disponibiliza logs/resultados e, em sucesso, o pacote Windows como artefatos da execução.

O runner falha em retorno não zero, erro de script/parse/compilação ou timeout nas etapas obrigatórias. Cada suíte usa um perfil isolado: não grava no save do desenvolvedor/jogador. Todas as suítes selecionadas são tentadas após uma importação bem-sucedida; o resumo fica em `results.json`, com `required` distinguindo a preparação inicial do gate obrigatório.

As duas suítes de menu também rejeitam avisos de instâncias vazadas/recursos ainda em uso. O teste de ciclo de vida acompanha nós, sessões, players e streams por referências fracas, com espera limitada pela liberação assíncrona do mixer, e verifica que a contagem de nós/órfãos não cresce em cinco ciclos.

A suíte de resiliência usa arquivos descartáveis e uma subclasse de teste para injetar falhas nas fronteiras de escrita/cópia/rename. Confere recuperação, recompensa idempotente, ausência de confirmação em memória antes do commit, formatos incompatíveis e temporários incompletos. Isso não simula falta física de energia nem certifica uso simultâneo por vários processos.

Além dessas suítes, a CI executa `godot/ValidarInterrupcoes.ps1`: 16 casos com encerramento real do filho Godot e duas reaberturas independentes, usando apenas fixtures descartáveis. Inclui save, depósito global, recompensa pendente, exclusão e restauração. Rodar somente `Validar.ps1` não inclui esse gate separado. [Matriz, comando e limites](refinamentos/r42-processos/README.md).

`save_feedback_checks` exercita o frontend real com erros injetados e entradas de teclado/gamepad simuladas. Confere cards de versão/corrupção/IO, recuperação por backup, retry e pausa/restauração dos avisos. Capturas opcionais exigem renderizador gráfico: executar a suíte sem `--headless`, com `-- --capture`; imagens em `tmp/save-feedback`.

Esse conjunto é uma regressão inicial explícita, não a totalidade dos testes existentes e não uma aprovação comercial da versão. Exportar com sucesso não substitui abrir o pacote em instalação limpa e fazer playtest.

## Rodar localmente

Com PowerShell 7, a partir da raiz do repositório:

```powershell
./godot/Validar.ps1 -GodotPath 'C:/caminho/Godot_v4.7.2-stable_win64_console.exe'
```

`-OutputDirectory` escolhe a pasta de resultados; o padrão cria pasta única no temporário. `-TimeoutSeconds` define o limite por suíte. `-SkipImport` serve apenas para diagnóstico com recursos já importados; a CI sempre importa.

O pacote release exige templates instalados no perfil do exportador. A CI instala isso automaticamente; executar o runner de testes sozinho não instala templates nem prova a exportação.

Depois de exportar, com uma pasta nova para os resultados:

```powershell
./godot/ValidarPacote.ps1 -PackageDirectory 'C:/build/release' -OutputDirectory 'C:/teste-pacote-novo'
```

O release oficial não aceita necessariamente `--script`: essa opção depende de suporte a path overrides no template. Por isso as sondas exportadas entram pela cena principal, exigindo **simultaneamente** `SOULMONSTERS_PACKAGE_PROBE=1` e argumentos de usuário `--package-probe resources|create|resume`. O dispatcher aceita somente esses modos fixos, não um caminho arbitrário de script. Sem os dois sinais o título normal continua sendo aberto. O wrapper `export_resources.gd` permanece disponível para `--script` no editor.

Essa prova cobre persistência e mudança de pasta do mesmo pacote. Não comprova migração entre versões, instalação Steam, VM limpa, renderização visual ou funcionamento de todo o jogo.

## Política do PR

Não apagar verificações de geometria para aceitar mapas novos e não achatar mapas Godot para o antigo renderer web. Os arquivos web históricos permanecem no repositório, sem execução no gate Godot.

Se a proteção da branch exigir nominalmente o check antigo `demo`, o administrador deve trocar esse requisito por `godot`, após a primeira execução do novo workflow. Não marcar um check vazio como sucesso para contornar proteção. O estado dessa configuração privada precisa ser conferido no GitHub; não foi alterado pelo workflow.

O workflow não faz deploy, publicação Steam nem merge. A primeira execução no GitHub ainda precisa confirmar download, permissões, instalação dos templates e exportação no ambiente do runner.
