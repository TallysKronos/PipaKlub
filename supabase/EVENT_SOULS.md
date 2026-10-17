# Souls especiais de evento

A migração `004_event_souls.sql` cadastra Flautrevo (Técnica), Trinca-brasas
(Guardiã), Alvaneve (Precisa) e Chaspiral (Ágil). Os atributos de combate são
os mesmos das quatro classes existentes. A aparência vem do inventário validado
pelo servidor; o cliente não escolhe uma especial ao criar ou entrar em salas.

São itens permanentes, vinculados à conta. Podem ser usados no treino e em
salas casuais. Vale pipa exige uma colecionável comum. Novos cadastros continuam
recebendo apenas as quatro pipas iniciais.

## Conceder uma recompensa

O administrador executa no SQL Editor do próprio projeto, substituindo o UUID
pelo perfil que efetivamente ganhou o evento:

```sql
select public.grant_event_soul(
 'UUID_DO_JOGADOR', 'flautrevo', 'nome-do-evento-2026'
);
```

IDs disponíveis: `flautrevo`, `trinca-brasas`, `alvaneve`, `chaspiral`.
A concessão é atômica e idempotente: o mesmo jogador recebe apenas uma cópia
de cada especial, mesmo se a operação for repetida em outro evento.
`soul_event_rewards` registra a origem e a data de cada concessão.

Visitantes, jogadores autenticados, o servidor restrito e `service_role` não
têm permissão para chamar essa função. Não há endpoint público de concessão.
As permissões do servidor de jogo continuam limitadas às quatro funções de
partidas. A organização de eventos e a seleção dos vencedores são manuais;
esta versão não inclui agenda ou painel de administração de eventos.

## Arte e animação

Os quatro PNGs estão em `assets/creatures/especiais/` e seus retângulos reais,
tempos e estados estão em `assets/atlas.json`. Cada Soul tem 16 quadros:
repouso, voo, habilidade, dano e vitória. Os arquivos são carregados sob demanda,
sem adicionar os quatro spritesheets ao carregamento inicial do jogo.

Validação: `npm run build`, `npm run build:pages`, `npm run validate`, `npm test`.
