# Após os quatro rigs aprovados

## Concluído

Trovareta, Rabiolava, Glacerol e Tufanocorte possuem peças, rostos e seis ações. O dono revisou cada um no editor e enviou seus projetos. Esses arquivos foram preservados integralmente, com hash e normalizações documentadas em `author-import.json` de cada criatura. Geometria, pivôs, camadas, animações e pixels editados foram incorporados. Rigs estão na revisão 2.

## Constatação no código consultado

Na branch de Soulgen, os mapeamentos visuais em `godot/scripts/campaign/encounter_view.gd`, `morro_battle_view.gd` e `front_end.gd` ainda não contemplam os quatro. Nenhuma ocorrência dos quatro IDs foi encontrada no código Godot/JS pesquisado nesta revisão. Isso não prova ausência em branches de terceiros não integradas.

O script `tools/soulgen-studio/export-game.mjs` exporta apenas Carcará para a engine web legada. Executá-lo não integra automaticamente os guardiões no Godot. Não usá-lo como prova de integração.

## Próximo passo recomendado

**Piloto da Trovareta no Godot, em batalha de desenvolvimento**, antes de expandir o cadastro dos outros três. Validar:

1. Ler o contrato de animação real usado na batalha e decidir exportação de atlas ou reprodução do rig conforme o consumidor; preservar a revisão aprovada como fonte.
2. Importar arte e metadados na branch de jogo apropriada, por arquivos selecionados. Não mesclar a branch inteira de Soulgen sobre os menus provisórios: ela tem histórico de HUD que o dono pediu manter separado.
3. Conferir escala, orientação dos dois lados, ponto de apoio/enquadramento, rostos, loops e disparo do impacto no mesmo instante marcado no Soulgen.
4. Conferir a leitura sob HUD de boss e fundos de batalha reais, inclusive asa aberta e rabiolas nos extremos. As validações atuais de PNG e sampler não substituem esse teste.
5. Só então repetir para Rabiolava, Glacerol e Tufanocorte e ligar os encontros de história onde o roteiro/código estiverem prontos.

Não inventar atributos, raridade, habilidades, drop, capturabilidade ou encontros de campanha porque a arte está pronta. O piloto pode usar dados de teste claramente identificados e sem gravar campanha.

## Continuidade da produção artística

Após validar o caminho Soulgen → jogo, a prioridade narrativa proposta é **Retalho → Platyx → Rai/Saber**, recuperando as identidades existentes e sem redesenhar por dedução. Depois, novas espécies regionais e oito conceitos reservados. A relação entre Rai e o nome anterior Saber precisa ser conferida no roteiro/catálogo antes de criar duplicatas.

Este documento é recomendação de sequência, não afirma integração realizada nem inicia alterações de jogo por conta própria.
