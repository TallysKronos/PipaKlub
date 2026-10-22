# Oficina das Almas · construção e despertar

Implementação local de 22/10/2026 baseada nos dois blueprints. Substitui a interface de constelação por cinco etapas persistidas: armação, nós, papel, equilíbrio e união da rabiola. O despertar só aparece após a concessão confirmada pelo banco.

## Arte e animação

- `assets/workshop/v1/bench.png`: bancada ilustrada original, 1536×1024, gerada com `image_gen`.
- `assets/workshop/v1/rabbito-parts.png`: fonte RGBA original, 1536×1024; corpo, duas orelhas, rabiola, estudo de expressão feliz e armação. Não foi reduzida a uma paleta monocromática.
- `assets/workshop/v1/manifest.json`: recortes medidos, fontes e tamanho lógico da composição.
- `prompts.json`: prompts completos, ferramenta, referência de identidade e nomes das gerações originais.
- `asset-report.json`: validação técnica do PNG; não equivale a aprovação estética.
- `src/workshop-renderer.js`: composição compartilhada pela oficina do jogo e pela prévia. Raízes das orelhas e da rabiola fixas; sombra separada da flutuação; varetas com chegada interpolada, aplicação progressiva do papel e aura breve no despertar. Movimento reduzido preserva a leitura das etapas.

O Rabbito recebeu um conjunto próprio de peças. A variante feliz permanece na fonte como estudo, **sem troca em runtime**, pois ainda não foi registrada pixel a pixel contra o corpo neutro. Evita-se a mudança de volume causada pela substituição de um corpo inteiro.

As outras espécies continuam usando seus atlas aprovados na etapa de equilíbrio/despertar. Compartilham um gabarito básico de quatro apoios; não possuem, nesta entrega, um conjunto anatômico recortado individual equivalente ao do Rabbito. Novos conjuntos devem acrescentar fonte, recortes e pivôs específicos sem substituir o desenho aprovado por uma recoloração do coelho.

## Uso e revisão

```powershell
node scripts/preview-workshop.mjs
```

Abra `http://127.0.0.1:5237/`. A prévia permite rever cada etapa, pausar, reduzir movimento, diminuir velocidade e construir novamente. É uma revisão visual sem conta e sem concessão de itens. Compartilha modelo e composição com o jogo; não simula persistência de produção.

`http://127.0.0.1:5237/mobile` abre a mesma prévia em um iframe com viewport interno 390×844. O empilhamento, a leitura de instruções e o acionamento dos controles foram inspecionados nesse viewport; isso não é um teste de aparelho físico. Captura em `review-mobile.png`.

Para a integração real em banco local isolado:

```powershell
node build.mjs
$env:LOCAL_TRADE_PORT='5236'
$env:LOCAL_TRADE_SLOT='soul-workshop-v2'
$env:LOCAL_WORKSHOP_FIXTURE='1'
node scripts/local-trades.mjs
```

Abra `http://127.0.0.1:5236/local/ana`, depois Menu → Clube → Oficina das Almas. A flag fornece uma rabiola de Rabbito e libera a abertura apenas para a conta local de Ana. Não muda a abertura comum e nunca é importada pelo servidor de produção. Se o servidor local reiniciar, use o endereço `/local/ana` para renovar a sessão de teste; a montagem permanece no banco local.

## Regras desta versão

- O ateliê fornece o kit básico de bambu, papel e linha. Ainda não há economia nova de coleta, estoque ou compra desses materiais; isso está explícito na preparação.
- Cada etapa é confirmada no servidor em ordem. Etapas incompletas podem ser refeitas sem perder a rabiola; o ajuste manual oferece alternativa assistida pelo Sr. Assis.
- Os quatro apoios podem ser acionados na bancada por mouse/toque ou por botões navegáveis no teclado. Corte é uma aplicação guiada por quatro partes, não recorte livre de precisão.
- Nós têm ajuste de tensão e opção de apertar no ritmo do marcador. Equilíbrio e união usam ajustes com prévia e indicador de qualidade.
- A rabiola fica reservada ao iniciar. Fechar, pausar ou recarregar não a danifica. A etapa em edição pode ser refeita; as etapas confirmadas são retomadas pela conta.
- Ao completar as cinco etapas, uma transação consome a rabiola e registra o parceiro uma única vez. O reenvio de confirmação mantém o mesmo identificador e o mesmo resultado.
- A qualidade é um registro da montagem. Não concede bônus de combate ou altera XP/classes.
- Rabiolas danificadas pelo ritual antigo podem ser restauradas gratuitamente, pelo próprio dono.
- O último despertar pode ser reaberto na oficina após uma resposta de conclusão perdida.
- Não foram implementados nesta entrega evolução, reparo de criaturas, desmontagem, bancada portátil, nove biomas ou novos drops de materiais.

## Validação

A suíte completa passou com **358 testes** na verificação final. Os testes novos cobrem propriedade de conta, ordem de etapas, recuperação do ritual antigo, reserva sem expiração, restauração, idempotência, concessão única, respostas atrasadas, reenvio após falha de rede e distribuição idêntica das imagens nos dois builds web. Testes de SQL legado foram limitados às migrações anteriores a 024 para preservar a cobertura histórica; o protocolo atual é coberto em `workshop.test.mjs` e na jornada de recompensas das Trilhas.

No navegador, o fluxo real foi percorrido até Rabbito aparecer selecionado na coleção da conta local. A página foi recarregada e a oficina retomou na etapa de equilíbrio. Captura `review-game-completed.png` usa apenas a conta de teste local, sem dados de jogadores de produção.

## Publicação

Esta entrega é local. A migração `supabase/migrations/024_soul_workshop.sql` precisa ser aplicada em conjunto com o novo servidor/cliente. Não publicar somente o cliente sobre o banco antigo. As autorizações anteriores de produção cobriam 017–023, portanto a migração 024 não foi aplicada em produção nesta atividade.
