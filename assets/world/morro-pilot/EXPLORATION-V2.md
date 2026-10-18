# Morro — fatia de exploração v2

## Comparação e escolha

A planta A usa subida com caminhos que se reencontram. A planta B organiza os mesmos encontros ao redor de uma praça central. B facilita orientação e retornos, mas exige reconstruir a implantação e corre o risco de parecer uma seleção de destinos distribuída no chão. A foi escolhida para preservar o relevo e testar descobertas com o kit existente. A comparação é uma avaliação de projeto; não houve teste A/B com jogadores.

## Aplicado

- Casa oeste e sua cobertura menores, liberando passagem lateral; cerca acompanha o novo limite.
- Segunda escada e terraço de conexão, mantendo as transições físicas entre pisos.
- Bia reposicionada junto ao novo terraço. A visita não libera seu desafio antes de Zeca.
- Pátio, recanto do banco, passagem da bananeira e beco que reconecta à viela principal. O desvio contorna a casa da esquina.
- Banco com base física. Vegetação lateral removida do caminho.
- Memórias do vento: descoberta narrativa opcional, aberta em diálogo com foco, fechamento pelo botão e Escape nativo. Não concede itens nem modifica progresso.
- Continuação passa a orientar para o Parque dos Ventos. O parque ainda não foi construído nesta fatia.
- Correção do telhado oeste após a auditoria visual: o primeiro reposicionamento deixava uma faixa vazia entre cobertura e fachada.

## Medição e testes

O trajeto mínimo entre a entrada e Bia tem 736 px. Desabilitando apenas a segunda escada no mesmo mapa, são 928 px: redução de 192 px, aproximadamente 21%. São medidas do grafo, sem contar diálogo ou batalha. O retorno funciona nos dois sentidos e fica disponível durante a exploração; não há desbloqueio fictício por interação.

O teste de percurso percorre descoberta, lateral da casa, beco, Bia e volta à entrada. Verifica pés e parceiro em terreno seguro a cada passo. Cada escada também é removida separadamente para comprovar que a outra mantém os destinos acessíveis. Os testes antigos que supunham uma única escada foram atualizados para aceitar várias, mantendo a exigência de que toda mudança de piso ocorra em uma delas.

A construção continua restrita a `?overworld=pilot`. O mapa normal da campanha conserva seus cinco encontros.

Validação executada: suíte completa com 227 testes aprovados; após o ajuste final da posição de Bia, 27 testes específicos de mapa e kit aprovados, incluindo um teste novo que exige ganho real de distância pela segunda escada. Builds Worker e Pages concluídos e artefato ESM validado. No navegador: clique no chão da passagem, subida pela segunda escada, aproximação de Bia e recusa do desafio bloqueado; abertura e fechamento da descoberta do pátio. Não foi feita uma nova campanha completa nem uma rodada com jogadores externos.

## Limites desta entrega

É uma primeira fatia para avaliar circulação. NPCs ainda usam os recortes anteriores; a composição do chão permanece modular e retangular. O pátio recebe uma descoberta textual, sem personagem novo animado. Não existem interiores, população ambiente, eventos persistentes, observação de espécies ou os três encontros seguintes neste piloto.

A próxima rodada deve observar jogadores novos antes de fechar a arte: qual escada escolhem, se percebem o desvio, se lembram da descoberta e se o retorno é útil. Não considerar aprovação automática dos testes técnicos como aprovação da diversão.
