# Resultados do Morro padronizados

O Morro usa o mesmo cartão ilustrado de resultados das demais batalhas: equipe, XP, subida de nível, dinheiro e itens. As estrelas e a passagem liberada continuam nesse cartão, com contexto “Recompensas do desafio · Morro do Sol”. O retrato compartilhado do Kael foi atualizado para a arte mangá aprovada usada na identidade.

Ao continuar, o mapa apresenta somente a conversa dos adversários, com nomes, retratos e paginação do diálogo atual. O aviso genérico “Aviso/Entendi” e o recibo de XP/moedas repetido foram removidos. O mesmo fluxo cobre vitória, derrota e desistência; o movimento volta ao fechar a conversa.

Na primeira vitória contra Mikka, a cerimônia da insígnia continua separada: fala da campeã, banner do item e acesso ao porta-emblemas. A fala também deixou de repetir o resumo numérico que já apareceu no cartão. A pausa para receber uma insígnia pendente reconhece controladores sem `path`, como o da Vila.

Nenhuma fórmula de recompensa, XP, dinheiro, estrelas ou transação de save foi alterada. A nova apresentação não concede um segundo prêmio.

## Verificação

- `morro_result_presentation_checks.gd`: 27 verificações, zero falhas. Cartão compartilhado, estrelas, passagem, contexto, duas resoluções, conversa dos NPCs, retorno ao movimento e ausência de prêmio duplicado nos três resultados.
- `reward_layout_checks.gd`: 1.604 verificações, zero falhas. Resultados comuns, Morro, chefe, derrota e desistência; quatro resoluções.
- `first_district_insignia_checks.gd`: 74 verificações, zero falhas.
- `morro_transaction_checks.gd`: 51 verificações, zero falhas.

Capturas nativas: `vitoria-1280x720.png`, `vitoria-1920x1080.png` e `dialogo-pos-vitoria.png`. Os testes usam saves isolados.

Pacote interno atualizado e executado fora do projeto: vitória ilustrada do Morro, confirmação da recompensa, conversa dos NPCs e retorno ao movimento conferidos. Saída 0, log sem erros; captura `vitoria-pacote.png`.
