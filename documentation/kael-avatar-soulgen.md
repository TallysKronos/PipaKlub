# Kael modular — revisão de entrega

A revisão inicial abaixo foi substituída após a auditoria visual solicitada pelo usuário. Estado atual: `art/soulgen/keys/kael-v2/README.md`; inclui quatro direções e verificação de sobreposição de pixels.

Implementado no Soulgen Studio em 23/10/2026. Fonte, projeto portátil e regras: `art/soulgen/keys/kael/README.md`.

## Verificação

- 29 testes do Studio passaram: modelo, workflow, editor, servidor, Eremor e Kael. Incluem as 64 combinações, exportação do atlas e reabertura estrutural do projeto incorporado.
- Encaixes dos ombros, pescoço e cabelo amostrados a 60 Hz nas seis ações, sem desvio dos pivôs; ciclos fecham na mesma pose.
- Auditoria executada também pela interface: estrutura, proporção e quatro encaixes sem avisos.
- Inspeção manual no navegador: visual padrão, pele escura, cabelo ondulado/acobreado, roupa terracota, caminhada, aceno no extremo e recuperação da aparência após recarregar. Corrigidos tênis voltados para dentro, alteração dos detalhes dourados pela paleta de pele, recortes retangulares ao redor dos olhos e quota da recuperação do preset local.
- Evidências: `documentation/evidence/kael-avatar/kael-original.png`, `kael-personalizado.png`, `auditoria.png`.

## Limites

Vista frontal de autoria. Caminhada/corrida são ciclos frontais de prévia. Costas/perfis, expressões faciais alternativas, seleção no início do jogo e persistência da aparência na conta não fazem parte desta entrega. O sprite atual do overworld permanece em uso.

Não houve push nem deploy nesta etapa. A validação se refere ao Studio; não é uma nova aprovação da geometria de todos os ambientes do jogo.
