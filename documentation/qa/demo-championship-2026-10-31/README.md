# Fechamento do primeiro bairro

Validação local do trecho Mikka → vitória → insígnia → porta-emblemas → reabertura, em Godot 4.7.2 com renderização nativa a 1280×720.

## Método e limites

Teste assistido automatizado, não um playtest humano completo. O save inicial isolado prepara os quatro desafios anteriores concluídos e Rabbito no nível 8, íntegro. A batalha da Mikka usa as ações normais de movimento, corte, habilidade e assinatura, lidas pela view nativa. Não altera HP, resultado ou número de rodadas para fabricar uma vitória. Os passos da batalha avançam em tempo simulado; confirmações usam os botões reais dos diálogos, após percorrer suas páginas.

O teste fica em `tmp/playtest-humanlike/appdata`, separado da campanha normal. O resultado não mede diversão, dificuldade para iniciantes ou a progressão completa até o nível 8.

## Resultado

- Vitória por 3 a 0 em aproximadamente 35,5 segundos simulados.
- Insígnia concedida pela transação de vitória; primeiro espaço ocupado, contador 1/12.
- Banner concluído pelo temporizador normal, seguido da abertura do porta-emblemas.
- Aplicação destruída e recriada, com nova sessão lendo o save do disco.
- Emblema, data, dinheiro e condição/XP do parceiro preservados. Sem repetição da cerimônia.
- **15 verificações, zero falhas.**

As comparações de persistência normalizam os números para o formato JSON: inteiros em memória são lidos como floats, sem mudança de valor. Não foi necessário alterar o código do jogo neste teste.

## Evidências

- `01-victory.png`: resultado da batalha.
- `02-earned-badge.png`: primeira insígnia no porta-emblemas.
- `03-reloaded-badge.png`: mesma conquista após recriar a aplicação.

Executar na raiz do repositório:

```powershell
$env:APPDATA = Join-Path (Get-Location) 'tmp/playtest-humanlike/appdata'
& ./godot/Godot_v4.7.2-stable_win64_console.exe --path godot --script res://tests/demo_championship_playthrough.gd
```

## Pacote para teste

Pasta local: `godot/exports/demo-test-2026-10-31/`. O pacote usa o executável Godot já instalado e um PCK exportado, com `Iniciar.cmd`. Trata-se de uma versão interna de teste, não uma release pública: templates oficiais Windows não foram encontrados na instalação padrão.

Executável e PCK foram executados fora da árvore do projeto, com armazenamento isolado. Smoke test headless: saída 0. Smoke test nativo: menu inicial e Praça da Campeã renderizados a 1280×720, saída 0 e sem erros no log de execução. Evidências: `04-packed-menu.png` e `05-packed-map.png`. Os hashes dos dois arquivos estão no `build-info.json` junto do pacote.

A exportação do PCK concluiu, mas o editor tentou gravar configurações na pasta de usuário sem permissão e precisou ser encerrado depois. Esses erros de encerramento não ocorreram na execução do pacote; os dois smoke tests acima conferiram o PCK resultante.
