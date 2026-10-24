# Primeiro voo, rabiola e Oficina

## Fluxo

O Sr. Assis conversa pelo mesmo balão usado na exploração, com retrato e **Avançar**. A arena fica parada enquanto ele explica. Durante o exercício, a orientação se reduz a uma legenda e os comandos controlam o parceiro. Ao cumprir o objetivo, o balão volta. O treino preserva movimento, cruzamento/ataque, recuperação de energia, habilidade, esquiva, rebicada e rodada com Nozinho.

Depois do primeiro treino completo, o professor oferece **uma** rabiola: Carcará (`basica`), Mata Verde (`mata`), Azulão (`azulao`) ou Raio de sol (`raio`). A escolha entrega somente o item. O próximo Avançar abre a Oficina v3 diretamente com a rabiola e o molde escolhidos. A montagem mantém suas regras reais de acertos, tempo, bônus e variante.

O tutorial só termina quando há um trabalho concluído no banco, da mesma conta/rabiola/espécie, ligado a um parceiro existente na coleção. A confirmação local da interface não concede recompensas. A cidade/Morro deixa de ser a conclusão imediata do treino.

## Persistência e compatibilidade

- Migração **027_starter_tutorial.sql**: registro por conta, RLS sem escrita direta, RPC autenticada com identidade do jogador e bloqueio de receitas incompatíveis para a rabiola do tutorial.
- Entrega idempotente por `event / first-flight-starter-v1`. Repetir o treino ou a requisição não gera outra rabiola.
- A escolha é definitiva. Sair/recarregar retoma o mesmo item e trabalho. Falha usa o fluxo existente de restauração gratuita da rabiola e nova tentativa, sem outro presente.
- A leitura reconcilia um nascimento já salvo caso o navegador tenha fechado antes de confirmar o fim do tutorial.
- Campanhas já concluídas e contas legadas mantêm seu progresso. Reprises não entregam presentes. Reiniciar a campanha não apaga a entrega registrada por conta.
- O servidor local aplica a migração apenas em seu próprio PGlite. Publicar esse fluxo em produção requer aplicar a migração 027 no Supabase; ela não foi aplicada em produção nesta alteração.

## Verificação desta entrega

Compilação dos dois destinos web e verificações de sintaxe JavaScript. Servidor local iniciado na porta 5260 com a migração instalada. Não foram executados testes automatizados nem validação completa jogando, conforme orientação do usuário. A aprovação do fluxo e da apresentação fica para a experiência local do usuário.

## Escolha de rabiola — direção visual

A seleção mantém o salão real visível, com contraste e desfoque leves, e quatro cards com as animações aprovadas dos starters. Cada moldura recebe uma cor de destaque associada à identidade do parceiro, sem introduzir elementos ou tipos novos. Um marcador da rabiola diferencia a entrega do item da criação do parceiro.

Os cards mostram ataque, velocidade de voo e defesa de `eng.pipamons.stats(1)`, sem bônus de montagem. As barras usam como teto os valores base no nível máximo da mesma engine; os valores numéricos permanecem visíveis. Atualmente todos os starters compartilham esses atributos base: a diferenciação está nas habilidades reais retornadas por `eng.type`, explicadas no comentário do professor. Nenhum número fictício foi atribuído a uma espécie para diferenciar os cards.

A HUD existente recebe acabamento contextual, preservando os dados de perfil, XP, moedas e missão. A seleção não permite caminhar pelo cenário. Mouse, toque e navegação existente por teclado/controle usam os mesmos botões e a mesma confirmação. A disposição passa de quatro para duas colunas em telas estreitas; em telas baixas, a seleção permite rolagem. Preferência por movimento reduzido continua respeitada.

Esta etapa teve compilação dos dois destinos e checagem de sintaxe; não teve execução de testes nem validação visual jogando.

## Oficina como ambiente de jogo

A bancada v3 agora aparece sobre o ateliê ilustrado, com título em placa, saída no canto e materiais em pequenas peças sobre o cenário. O wizard horizontal foi removido. Um selo circular discreto registra o avanço; a instrução atual permanece junto à bancada. As opções de prática ficam recolhidas, e não há seletor de dificuldade no modo autenticado.

O resultado usa uma folha de acabamento: parceiro, estrelas, tempo/erros e bônus total em destaque, com detalhamento expansível. O botão Continuar usa a mesma saída com salvamento da bancada. O texto confirma que o parceiro já foi salvo somente após confirmação do servidor. Falha continua preservando a rabiola e encaminha à Oficina; prática continua sem conceder parceiros.

A mudança é de apresentação. Não altera o modelo, as janelas de acerto, o cálculo de bônus, a chance de variante, as transações ou as migrações. Arte de origem documentada em `art/workshop-v3/atelier-v1.md`.

### Limite da ilustração do nascimento

A área `resultArt` tem altura reservada, não encolhe dentro da coluna do resultado e contém sua própria pintura. A imagem de prática e o Canvas autenticado ficam posicionados dentro dessa área, com margem e `object-fit: contain`, sem contribuir com seu tamanho natural para o fluxo. Assim, o desenho não passa sobre nome, bônus, detalhes ou botões. A correção foi compilada nos dois destinos; sem testes executados.
