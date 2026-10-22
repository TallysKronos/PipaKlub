# Revisão de anatomia e audit — Eremor v2

22/10/2026. Correção solicitada após o responsável apontar desproporção da cabeça e dificuldade de encaixe. A primeira validação cobria dados, pivôs e limites, mas não media proporções nem a ligação dos pontos desenhados na anatomia. Uma hierarquia matematicamente válida podia continuar visualmente incorreta.

## Correção da montagem

- Tronco: largura lógica de 153 para 184 (+20,3%). Cabeça: 97 para 76 (−21,6%) em relação ao primeiro preset. A relação entre larguras passou de 0,634 para 0,413. Esses números descrevem os retângulos de arte; não são uma medida biológica.
- Cabeça encaixada no pescoço; braços ligados aos ombros do tronco; base do leque e rabiola posicionadas em seus pontos de inserção.
- Velas, braço distante e rabiola desenhados atrás do tronco. Nó e braço próximo permanecem no primeiro plano.
- Preparação do golpe reduzida de 53° para 32° para melhorar a leitura do rosto e do braço levantado.
- Palco ampliado para 340×280 para manter margem durante o recuo. Fonte, cor e proporção interna de cada PNG preservadas.

A montagem editada pelo usuário foi salva pelo próprio editor antes da correção. Cópia local em `.local/eremor-audit/user-before.soulgen.json`; o arquivo baixado também permanece em Downloads. Não é substituída silenciosamente por uma migração de recuperação automática.

## Audit aprimorado

Projetos podem carregar referências anatômicas opcionais em `anatomy` v1. O preset v2 registra relação entre cabeça e tronco, ordem das camadas e seis pares de pontos de encaixe. São guias calibrados para esta revisão do Eremor, não limites universais para outras espécies.

O relatório compara os pontos de desenho das peças com os pontos do tronco durante todas as ações, a 30 amostras/s. Esses pontos são independentes dos pivôs de animação: arrastar uma peça e seu pivô juntos ainda pode produzir aviso de desconexão. Os testes complementares amostram limites e estabilidade a 60 Hz.

Avisos de anatomia, ciclos e margens agora aparecem no resumo em amarelo; não recebem o resumo verde de aprovação técnica sem ressalvas. São avisos de revisão: a exportação não é bloqueada por uma escolha artística que o autor possa querer manter. Erros estruturais/faciais continuam usando as regras de bloqueio existentes.

## Testes efetivamente executados

- **30 testes passaram** no conjunto Soulgen/Carcará, incluindo três testes do Eremor e o teste de avisos no controlador real do editor.
- Testes negativos: cabeça aumentada, peça deslocada junto do pivô, leque à frente do corpo e pivô de braço mal posicionado. O relatório detectou os desvios; o preset corrigido não apresentou avisos.
- No navegador, aumentei a largura da cabeça para 120. O audit mostrou relação 0,652 fora do intervalo 0,36–0,46 e desvio de encaixe de 36,1 unidades na vitória. Após Desfazer e executar novamente, a relação voltou a 0,413 e os seis encaixes ficaram dentro da tolerância, com maior desvio arredondado de 0,03 unidade.
- Inspeção das cinco ações no Soulgen, incluindo preparação em 0,85 s, impacto em 1,05 s, dano em 0,14 s, vitória em 1,30 s e reprodução da planagem.
- PNG e metadados exportados pela interface real. Verificação de **163 quadros**, transparência e correspondência das dimensões; zero quadros vazios ou cortes nas bordas. Resultado reproduzível em `export-audit-v2.json` e `audit-export.py`.

## Limites

O audit não reconhece por visão computacional o desenho de um ombro: ele compara os pontos cadastrados. Não substitui julgamento de silhueta, gosto ou aprovação artística do responsável. A cabeça ainda é neutra, sem novas variantes faciais. Não houve alteração no catálogo, banco, overworld, produção ou publicação Git neste ajuste.
