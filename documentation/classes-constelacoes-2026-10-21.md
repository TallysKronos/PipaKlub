# Classes e evolução por constelações

## Acesso e comportamento

Pipamons → detalhes do parceiro → **Classes**. A antiga entrada isolada de classes no Clube foi removida. A aba reserva a área de detalhes para a constelação e a inspeção dos requisitos. Espécies sem catálogo mostram que ainda não têm linhas definidas; não recebem classes inventadas.

Selecionar um nó apenas inspeciona requisitos e atributos. O botão **Desbloquear e assumir** realiza a operação no servidor. Nós ainda não descobertos usam silhuetas genéricas de coelho, sem antecipar as ilustrações futuras. Nós descobertos ficam iluminados; o atual recebe destaque dourado. O caminho original também pode ser reassumido.

Nome, ID, XP, nível, banco e propriedade são conservados. Descobertas pertencem à instância do Pipamon, não a todos os indivíduos da espécie. Reassumir uma descoberta é gratuito. Desbloquear pela primeira vez consome o item exigido, quando houver. Voltar para outra linha não transfere automaticamente seus avanços: cada ramo precisa ser desenvolvido.

Setas navegam pelos nós; Enter/A seleciona. Tab ou navegação espacial alcança a confirmação. O quadro de requisitos aceita foco e rolagem; no controle, esquerda volta à constelação. Controle físico ainda exige validação em hardware.

## Rabbito: três classes iniciais

Nomes dos avanços, requisitos, efeitos e aquisição dos itens abaixo são **balanceamento inicial configurável**, não requisitos finais de lançamento. Rabbitknight é uma classe especial sem sucessores, e não uma cópia única por conta.

| Linha / estágio | Nível | Atributo base mínimo | Item no primeiro desbloqueio |
|---|---:|---|---|
| Velocista | 15 | velocidade 168 | — |
| Rastro dos Ventos | 35 | velocidade 173 | — |
| Arauto da Tempestade | 45 | velocidade 176 | Pluma dos Ventos |
| Condutor | 15 | recuperação 18,4 | — |
| Mestre dos Fios | 35 | recuperação 19 | — |
| Tecelão da Aurora | 45 | recuperação 19,5 | Carretel Celeste |
| Rabbitknight | 25 | ataque 1,05 | Máscara do Guerreiro |

Cada avanço das duas linhas comuns exige a descoberta do anterior. Rabbitknight nasce diretamente do nó de Rabbito, sem evoluções posteriores. Conceito visual reservado: coelho com luvas de boxe e máscara bucal de guerreiro. Os sprites e layouts próprios não foram produzidos nesta etapa, conforme decisão do projeto.

Os requisitos usam atributos **base**, sem bônus da classe equipada. Assim, mudar de classe não permite fabricar um requisito artificialmente. No sistema atual estes atributos crescem com o nível; ainda não existem pontos livres de distribuição ou treinamento de atributos independentes.

### Efeitos reais em combate

- Velocista / Rastro / Arauto: velocidade +8%/+16%/+24%; recuperação +4%/+8%/+12%; linha −5%.
- Condutor / Mestre / Tecelão: ataque +4%/+8%/+12%; recuperação +8%/+16%/+24%; velocidade −5%.
- Rabbitknight: ataque +15%, defesa +8%, velocidade −8%, recuperação −5%.

São modificadores passivos dos atributos existentes, aplicados pelo mesmo motor no servidor, previsão de movimento e ficha. Não foram criadas habilidades ativas exclusivas nem novas animações de ataque. A identidade visual em batalha mantém os sprites atuais até receber as artes definitivas.

## Itens especiais

A cada cinco vitórias verificadas no parque: Pluma na 5ª, Carretel na 10ª, Máscara na 15ª; o ciclo repete na 20ª/25ª/30ª e assim por diante. Derrota, fuga e abandono não contam. A tela de resultado anuncia o item e a aba Classes mostra saldos e distância até o próximo marco.

Recibos únicos por conta e marco impedem duplicação por reconexão ou reset. Há reposição por novos ciclos para que outros parceiros também possam desbloquear os caminhos. Itens pertencem à conta e sobrevivem ao reset; descobertas sobrevivem somente para os Pipamons preservados. Um novo Rabbito começa com sua própria constelação não descoberta.

## Persistência e migração

Aplicar **023_class_constellations.sql** depois de 001–022, antes de publicar o servidor. Transação única. O ambiente local instala apenas se a tabela do catálogo estiver ausente. Nenhuma migração foi aplicada em produção nesta entrega.

Catálogo de nós: `pipamon_class_nodes`; descobertas: `pipamon_class_unlocks`; saldo: `player_class_items`; recibos: `class_item_receipts`. As tabelas são privadas com RLS. `player_classes` autentica o proprietário, bloqueia o perfil/parceiro e confere versão, nível, atributo, predecessor e item na mesma transação. Partida, troca ou ritual ativos bloqueiam mudanças. A rota antiga de especialização foi desativada para não permitir contornar os requisitos.

Classes legadas são preservadas: os estágios já existentes viram descobertas da linha correspondente. O máximo de estágio passa a três; limites de níveis continuam tamer 100/Pipamon 50. O resultado de encontro inclui recibos dos itens de classe e mantém a repetição idempotente. Marcos de vitórias anteriores são reconhecidos uma vez na migração.

## Validação

Testes PostgreSQL verificam acesso entre contas, requisitos de nível e atributo, predecessor, consumo único, reespecialização gratuita, preservação de nome/XP, controle de versão, dois Rabbitknights na mesma conta, reset com parceiro preservado, saldo privado e ciclos repetíveis sem duplicação. Teste da interface verifica aba própria, silhuetas, bloqueio por requisito e ausência de mutação ao inspecionar um nó. A suíte completa passou com 324 testes antes dos ajustes finais de navegação; estes são verificados novamente na entrega.
