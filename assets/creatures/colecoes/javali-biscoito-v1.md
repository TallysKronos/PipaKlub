# Javali de Biscoito — auditoria

Nome provisório; novo Pipamon, sem substituir os existentes. Total atual: 34 registros na Dex.

## Aplicação

- PNG original preservado byte a byte, inclusive transparência, partículas e efeitos. SHA-256: e3b6acba4a20532cd659e5fd4ba6eb3fc1dbe1b69f0f470c725498b00bd4b4e0.
- Folha 1254×1254. Limites em X e Y: 0, 314, 627, 941 e 1254. Os 16 retângulos cobrem a folha inteira, sem sobreposição.
- Estados: repouso 00–03, voo 04–07, habilidade 08–11, dano 12–13, vitória 14–15.
- Enquadramento comum 314×314; células de 313 px mantêm uma faixa vazia de 1 px, sem zoom por pose. A leitura fica limitada ao retângulo do quadro, evitando pegar o vizinho.
- Compatível com direção esquerda/direita, rebicada, modo leve e movimento reduzido.

## Conferência

110 testes validados, incluindo os 16 retângulos, escala constante, cinco estados, catálogo e distribuição dos arquivos. Build Worker/Pages e artefato válidos. Equipado pela interface na conta Ana do banco local, exibido em treino e na Dex, sem erros no navegador. Concessão de demonstração idempotente e restrita ao script local.

Alguns efeitos já encostam nas bordas da imagem enviada; pixels externos ausentes não foram reconstruídos. Nenhum efeito foi removido. A página HTML de auditoria permite inspecionar os 16 quadros e cinco animações em fundos diferentes e inverter a direção.

## Publicação

Migração 012_javali_biscoito.sql registra o modelo para concessão administrativa de evento. Não concede inventário em produção nem cria drops. A rabiola está cadastrada como item de evento. A migração 013_javali_summoning.sql registra o feitiço em espiral para usar a receita da própria rabiola. O fluxo completo e os cenários de falha foram auditados; veja INVOCACAO-JAVALI.md. O nome é provisório; o ID javali-biscoito é estável. Não houve merge, migração ou deploy em produção.
