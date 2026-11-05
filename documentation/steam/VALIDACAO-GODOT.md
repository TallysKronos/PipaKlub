# Validação do PR — produto Godot

Atualizado em 05/11/2026. O produto ativo é exclusivamente a campanha Godot. A versão web e seus conversores de mapa não são critérios de aceite do jogo atual.

## Verificação automática

`.github/workflows/godot.yml` substitui o antigo workflow `Demo validation`:

1. Baixa Godot **4.7.2 stable** e templates correspondentes da distribuição oficial, verificando SHA-512.
2. Prepara a importação inicial e exige uma segunda passagem sem erros em `godot/Validar.ps1`, em Windows. Na primeira abertura sem cache, o tema pode tentar resolver fontes/imagens antes de serem importadas; o log inicial é preservado como diagnóstico não bloqueante apenas se o processo encerrar normalmente. Erros que persistam na segunda passagem bloqueiam a execução.
3. Executa 15 suítes de regressão: overworld, Morro, campanha/saves, controles, história final, encenação, viagens release, avisos após load, nomes, flor, recuperação da cidade, reunião, apresentação/libertação Trovareta e fluxo Beira-Canal.
4. Verifica também os recursos importados do título, casa, loja e previews, e gera a exportação Windows release por `godot/Exportar.ps1`. O exportador rejeita erros no log mesmo com retorno zero e executa a mesma sonda de recursos no executável/PCK entregue, fora da pasta fonte, com perfil temporário isolado.
5. Disponibiliza logs/resultados e, em sucesso, o pacote Windows como artefatos da execução.

O runner falha em retorno não zero, erro de script/parse/compilação ou timeout nas etapas obrigatórias. Cada suíte usa um perfil isolado: não grava no save do desenvolvedor/jogador. Todas as suítes selecionadas são tentadas após uma importação bem-sucedida; o resumo fica em `results.json`, com `required` distinguindo a preparação inicial do gate obrigatório.

Esse conjunto é uma regressão inicial explícita, não a totalidade dos testes existentes e não uma aprovação comercial da versão. Exportar com sucesso não substitui abrir o pacote em instalação limpa e fazer playtest.

## Rodar localmente

Com PowerShell 7, a partir da raiz do repositório:

```powershell
./godot/Validar.ps1 -GodotPath 'C:/caminho/Godot_v4.7.2-stable_win64_console.exe'
```

`-OutputDirectory` escolhe a pasta de resultados; o padrão cria pasta única no temporário. `-TimeoutSeconds` define o limite por suíte. `-SkipImport` serve apenas para diagnóstico com recursos já importados; a CI sempre importa.

O pacote release exige templates instalados no perfil do exportador. A CI instala isso automaticamente; executar o runner de testes sozinho não instala templates nem prova a exportação.

## Política do PR

Não apagar verificações de geometria para aceitar mapas novos e não achatar mapas Godot para o antigo renderer web. Os arquivos web históricos permanecem no repositório, sem execução no gate Godot.

Se a proteção da branch exigir nominalmente o check antigo `demo`, o administrador deve trocar esse requisito por `godot`, após a primeira execução do novo workflow. Não marcar um check vazio como sucesso para contornar proteção. O estado dessa configuração privada precisa ser conferido no GitHub; não foi alterado pelo workflow.

O workflow não faz deploy, publicação Steam nem merge. A primeira execução no GitHub ainda precisa confirmar download, permissões, instalação dos templates e exportação no ambiente do runner.
