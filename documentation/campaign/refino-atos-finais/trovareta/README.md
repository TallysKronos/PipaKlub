# F19 — Trovareta correta e continuidade da tempestade

## Mudanças

O rig aprovado da Trovareta estava no repositório, mas a campanha ainda usava Raio de Sol como imagem. O atlas original foi integrado sem repintura, com seis ações e 123 quadros. A criatura correta agora aparece no Bosque, no duelo e na ativação da torre.

A cena presa mantém a linha negra de Navalha. O ciclo de repouso usa uma âncora fixa para evitar saltos entre quadros; movimento reduzido mantém uma pose. O duelo utiliza o sampler Soulgen existente, sem alterar dano, nível, regras, concessões ou formato do save.

Ao atualizar o estado após a libertação, a apresentação substitui a criatura presa pelo Rato. Navalha não fica no mapa depois da conclusão, a chuva e o escurecimento terminam e uma segunda atualização não duplica os atores. O Rato usa o spritesheet overworld aprovado e fica numa passagem da mesma altura, separado de Kael; a posição anterior deixava o corpo encoberto por um barranco.

## Verificado

- TROVARETA PRESENTATION: 17 checks; 0 failures.
- Três testes Node do rig e da integração passaram, incluindo igualdade do PNG copiado com a fonte aprovada.
- Importador executado novamente sem alterar a saída.
- ENDGAME STORY: 98 checks; 0 failures.
- Endgame staging: 0 failures.
- Capturas em 1280×720 revisadas: bound.png, rato.png e battle.png.

## Limites

As capturas e transições de estado usam progresso preparado. Não houve uma partida humana completa contra Navalha e Trovareta, nem nova gravação do diálogo de convite do Rato de ponta a ponta. O duelo continua com mecânica de Raio por compatibilidade; golpes exclusivos e balanceamento ficam para depois.

O movimento é o Soulgen de três quartos aprovado. Não é uma nova animação de caminhada em oito direções. O corte da linha, a partida em voo e a entrada caminhando do Rato ainda não compõem uma cutscene completa nesta entrega. O terreno e as ligações do Bosque não foram alterados.

Sem merge, publicação ou push nesta etapa.
