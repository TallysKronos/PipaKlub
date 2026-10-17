# Cidade — pacote de arte v1

Status: prévia de arte preparada para revisão. Não integrado à campanha ou à economia. Nenhum deploy, alteração de conta ou recompensa.

## Conteúdo

- `mapa.png`: cidade litorânea 2D de 1536×1024, doze marcos de bairro e arena municipal no alto. Sem texto incorporado; marcadores e nomes são sobrepostos pela interface.
- `insignias.png`: doze insígnias transparentes, 1448×1086.
- `campeoes.png`: nove campeões novos em pose-base de corpo inteiro, 1265×1243. São sprites estáticos, não ciclos de caminhada/combate.
- `rivais.png`: 48 retratos transparentes, quatro por bairro, 1448×1086. São bustos para seleção/diálogo, não sprites de corpo inteiro.
- `efeitos.png`: 16 quadros em quatro sequências de quatro quadros — conquista, defesa, desafio e reconquista — 1231×1277.
- `manifest.json`: nomes, IDs propostos, coordenadas dos marcadores, associação de retratos e recortes reais, com hashes das folhas.
- `PROMPTS.json`: prompts completos e correções; gerados pela ferramenta integrada `image_gen`, sem CLI/API própria.
- `preview.html`: galeria navegável, com seleção dos doze bairros e reprodução dos efeitos. Usa arquivos locais; reaproveita as folhas existentes de Mikka, Lohan e Kleie.

## Bairros e campeões propostos

| Bairro | Campeão |
| --- | --- |
| Morro do Sol | Mikka (existente) |
| Beira-Mar | Lohan (existente) |
| Campanários | Kleie (existente) |
| Mercado das Cores | Nara |
| Vila das Pontes | Iuri |
| Jardim das Brisas | Flora |
| Bairro das Oficinas | Bento |
| Estação Aurora | Nina |
| Alto das Estrelas | Ayla |
| Quadra Rubra | Davi |
| Vila das Lanternas | Yuna |
| Serra dos Ventos | Ravi |

Nomes e identidades novos são propostas, sujeitos à revisão do criador. Os três IDs atuais (`morro`, `praia`, `torres`) são preservados. Os IDs novos não estão registrados no catálogo de batalhas nem no banco.

## Recorte e animação

As dimensões e o espaçamento devolvidos pela geração não correspondem a uma grade matemática perfeita. Não usar divisão cega em partes iguais. O manifesto registra retângulos por figura, medidos pelos espaços transparentes entre os elementos. Os PNGs foram copiados sem alterar os pixels ou o canal alfa.

`frames[].cell` é a célula de origem; `x/y/w/h` é o retângulo visual aparado. Personagens estáticos e insígnias podem usar o retângulo aparado. Efeitos devem usar a célula inteira para manter a escala entre o brilho inicial e a expansão. Quatro quadros a 7 fps, sem repetição automática; velocidade ainda é ajustável no jogo. Espelhamento e animações de locomoção não são parte deste pacote.

Para verificar dimensões, transparência, hashes, limites dos recortes e gerar a prévia, executar a partir da raiz: `node scripts/build-city-preview.mjs`. Um argumento opcional recebe o caminho de um HTML autocontido para compartilhar, sem depender das pastas de assets.

## Auditoria

Verificação de arquivos: 12 bairros, 12 insígnias, nove poses-base novas, 48 retratos e 16 quadros de efeito. Metadados PNG, alfa, hashes e limites dos recortes aprovados. Prévia percorrida com Playwright nos doze bairros, com reprodução das quatro sequências; console sem erros. Conferência visual das folhas e dos recortes apresentados no navegador.

Correções realizadas: margens na folha dos campeões; retrato inicial de rival parecido com Mikka substituído por cabelo castanho curto sem óculos; separação dos retratos; escala dos efeitos preservada entre os quadros.

## Ainda necessário para a campanha

Integrar mapa, encontros, títulos e recompensas ao estado da conta; escrever os diálogos e estabelecer os oponentes da final municipal. Produzir ciclos de animação adicionais se os NPCs forem andar pelo cenário, novos cenários de duelo para os nove bairros e artes específicas dos participantes da final após definir sua composição. Este pacote não implementa os 60 combates nem a disputa de títulos.
