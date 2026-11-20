# Entrega local — 12/11/2026

194/194 Soulmonsters registrados no runtime com idle e deslocamento, oito quadros por vista/ciclo. São 6.208 quadros, 388 atlas PNG e 194 editáveis Aseprite. O piloto Azulfazo usa seu rig específico; os outros 193 usam rigs regionais semiautomáticos, parametrizados por criatura e anatomia. Os arquivos estáticos aprovados foram preservados.

## Validação concluída

| Verificação | Resultado |
| --- | --- |
| QA de imagens do lote novo | 193/193 sem pendências; 6.176 quadros |
| Volume opaco do lote novo | Variação absoluta máxima de 4,98% da base por vista |
| Paleta, limites do apoio e novos fragmentos | Sem falhas nas condições do validador |
| Editáveis Aseprite versus PNGs | 7.760 verificações, zero erros em 194 modelos |
| Cópias de runtime versus exportações | 388/388 idênticas byte a byte |
| Testes de reprodução e direções | 3.916 verificações, zero falhas |
| Regressão de companheiros | 518 verificações, zero falhas |
| Percurso gráfico com caminhada/corrida | 3.688 verificações, zero falhas em 11 criaturas |

Os testes de direção foram atualizados para o novo contrato: nas animações, a vista traseira ocupa a segunda linha, enquanto as colunas representam quadros. A orientação antiga por duas colunas continua verificada na pose estática inicial.

O percurso usa o caminho e a física de produção com save isolado, câmera em zoom 1, janela 1280×720 e CRT desligado. Amostras: Farpim, Papisco, Azulfazo, Capibaluarte, Trovareta, Alvacordo, Aurorastro jovem, Anaconda jovem, Auriflama, Marulume e Viúva jovem. [Capturas](in-game/amostras.png) e [resultado estruturado](in-game/resultado.json); há GIFs de cada uma na mesma pasta. Não é um playtest humano completo nem uma auditoria de todas as resoluções.

Os logs ainda registram avisos anteriores de NPCs Cauê/Celina e de acesso ao diretório de configurações/log do editor. Não foram tratados como resolvidos por esta entrega.

## Revisão artística e limites

As nove pranchas estáticas foram inspecionadas para agrupar anatomias. Revisão independente das sete anatomias: 7/10 para ciclos funcionais. Comparações adicionais aprovaram a correção de emendas em Alvacordo/Bocobasto e a estabilidade de corpo com pés alternados em Rabbito/Platyx. O revisor não certificou visualmente cada uma das 194 criaturas.

A passada é deliberadamente curta; asas usam flexão regional, não novas poses de voo completo. Algumas pequenas formas mantêm cabeça/tronco estáveis na caminhada para preservar legibilidade e volume. A galeria permite escolher quais criaturas merecem uma segunda passagem com poses exclusivas. Esta entrega é uma primeira camada funcional de movimento, não 194 animações exclusivas redesenhadas quadro a quadro.

## Economia e manutenção

O QA incremental tem assinatura dos PNGs, base e parâmetros. A repetição sem alterações foi medida em aproximadamente 1,5 segundo neste computador. A exportação não recopia PNGs idênticos. Falhas podem ser regeneradas por ID com `--script-param only=id1,id2` no gerador Aseprite, sem reconstruir o catálogo. Os parâmetros específicos das exceções estão no roster; não dependem da memória do chat. Nenhuma nova geração de imagem ou vídeo foi usada no lote.

Integração local concluída. Sem commit ou push nesta etapa.
