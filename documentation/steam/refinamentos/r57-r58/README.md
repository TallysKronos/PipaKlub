# Primeiro pacote — importação limpa e recursos exportados

05/11/2026. Itens [R57/R58 do plano](../../PLANO-DETALHADO-DE-REFINAMENTO-GODOT.md). Base `088a9319` mais as alterações deste pacote.

## Problemas confirmados

1. A execução GitHub `42011753346` encerrava na importação: tema personalizado tentava carregar fontes e marcadores ainda não importados. O processo retornava zero, mas o runner corretamente encontrava erros no log. A preparação de cache precisava ser separada da validação obrigatória posterior.
2. Casa, loja, previews de saves e fallback do título usavam `Image.load_from_file` para imagens internas do projeto. Isso depende de arquivos crus e não representa o contrato normal de textura importada no pacote.
3. Na prova local de exportação houve erro de gravação temporária do ambiente, gerando `project.binary` inválido mesmo com retorno zero. O primeiro pacote foi rejeitado e regenerado com acesso adequado. Isso comprovou que conferir apenas o exit code do exportador era insuficiente.

## Alterações

- `Validar.ps1` registra `import-bootstrap` com `required=false` e exige processo concluído normalmente. Em seguida executa `import` obrigatório, que rejeita os erros persistentes. Logs das duas passagens são preservados. Não removeu a checagem de erro das suítes.
- Casa/loja/título/previews passam a carregar `Texture2D` importada; o teste de existência de props da casa usa `ResourceLoader.exists`, não existência do PNG cru.
- `PixelgenSprites` mantém sua leitura de arquivo **somente no fluxo de edição/hot reload já protegido**; seu caminho de pacote continua carregando recurso importado. Não foi removida a atualização artística local.
- Nova sonda `scripts/diagnostics/export_resources.gd` abre manifests, fontes/tema, móveis reais da casa, dono/móveis da loja, previews e título, verificando texturas importadas. Não inicia campanha nem grava progresso.
- Runner inclui a sonda em editor. `Exportar.ps1` passa a rejeitar erros no log e a executar a sonda no exe/PCK exportado, de fora da fonte e em perfil descartável. O marcador de conclusão também é exigido para evitar falso sucesso por interrupção.

## Evidências locais

| Verificação | Resultado |
| --- | --- |
| Fixture nova, sem `.godot`, com tema e 17 recursos | Primeira passagem: 52 erros de resolução antes da importação, exit 0. Segunda passagem: zero erros, exit 0. Logs `import-bootstrap.txt` e `import-verified.txt`. |
| Sonda no projeto | 58 checks, zero falhas. |
| Sonda usando o PCK exportado, com diretório de trabalho fora da fonte | 58 checks, zero falhas e sem erros de `project.binary`/recurso no log. `pack-resources.txt`. |
| Casa moderna | 79 checks, zero falhas, 1807/4680 amostras de alcance; sem acesso a save. |
| Loja moderna | 47 checks, zero falhas; 6696 amostras de alcance, zero bolsões isolados. |
| Menu do título | 349 checks, zero falhas funcionais; **6 instâncias e 2 recursos ainda vivos no teardown**, pendência R59. |
| PowerShell | Scripts de validação/exportação sem erros de sintaxe. |

Hash/tamanho do PCK e resumo em `results.json`. O binário de centenas de MB é artefato de teste local, não foi acrescentado ao repositório.

## Limites e próximo passo

O teste PCK foi executado pelo motor Godot 4.7.2 com o pacote montado; **não equivale a instalar e testar o executável Windows release final**. A nova etapa do exportador cobre esse executável na CI, mas seu resultado ainda precisa ser confirmado. Não foi feita certificação de instalação Steam, todos os recursos do jogo ou playtest visual de campanha.

R57 fica **implementado aguardando confirmação da CI completa**. R58 fica **corrigido e validado no recorte título/casa/loja/previews e no PCK**, com execução Windows final e inventário restante pendentes. R59 foi observado, não concluído. Não se declara todo o pacote A ou a 1.0 aprovados por esses resultados.
