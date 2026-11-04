# Prompt para o Codex: personagens 2D mangá com personalidade

Cole o bloco abaixo no fim de qualquer pedido ao Codex que envolva **prancha de silhuetas**, **exploração de personagem** ou **prancha de personagem**. Troque só o que está entre `< >`.

A base é o estudo do acervo de concept art da Bulbagarden (`art/benchmarks/bulbagarden-concept-2026-10-30/ESTUDO.md`) e a skill `.agents/skills/soulmonsters-concept-personagens/`.

---

```text
REGRAS DE CONCEPT DE PERSONAGEM (Soulmonsters)

Antes de desenhar, leia:
- art/benchmarks/bulbagarden-concept-2026-10-30/ESTUDO.md (seções 4 a 17, 21 e 22);
- .agents/skills/soulmonsters-concept-personagens/SKILL.md e references/;
- documentation/historia/BIBLIA-DA-HISTORIA.md, para o papel do personagem na história.

O objetivo é o nível de personalidade dos concepts oficiais de Pokémon do estudo
(Black/White, Sun/Moon, Sword/Shield, Scarlet/Violet): cada personagem é uma PESSOA
específica, reconhecível sem a roupa, sem a cor e sem o objeto. Não é copiar nenhum
personagem de lá: aprender as relações de forma, gesto e documentação e criar soluções próprias.

1. ACABAMENTO É FIXO, A PESSOA NÃO
- Use o Kael (art/characters/parque-pipeiros-v3/references/kael-estilo.png e a prancha do
  Kael da skill) só para LINHA, COR e SOMBRA: linha fina escura e uniforme, cor chapada levemente
  suave, uma sombra dura por material, olhos com um brilho, pouca textura, mangá 2D limpo.
- O Kael NÃO dá o rosto, o topete, a altura nem o corpo dos outros. Varie de verdade: altura,
  largura, comprimento de braços e pernas, mandíbula, nariz, olhos, distância entre feições,
  eixo da coluna e apoio dos pés. Adulto não vira criança; corpulento não é automaticamente
  cômico; esguio não é automaticamente vilão.

2. DEFINA A PESSOA ANTES DA ROUPA (escreva no brief.md)
- Desejo, contradição, hábito do dia a dia e uma tarefa que ela faz com as mãos.
- Como ocupa espaço: invade ou espera encostada? olha de cima ou ergue o queixo? mãos livres
  ou ocupadas?
- Papel na história (campeão, capanga, figurante, rival) e o parceiro Soulmonster dela.

3. EXPLORE ANTES DE FINALIZAR (nunca entregue uma prancha final na primeira rodada)
Primeira entrega: uma PRANCHA DE EXPLORAÇÃO com TRÊS ARQUITETURAS diferentes da mesma
pessoa. Elas diferem em corpo, cabeça e postura, não só na roupa. Para cada arquitetura:
  a) contorno em preto chapado, corpo inteiro (massa e espaços vazios);
  b) a mesma figura em blocos de três valores (cabeça, tronco e membros separados);
  c) a cabeça em linha, SEM cabelo e SEM acessórios (a pessoa tem que existir sem o topete);
  d) uma pequena cena de uso: a tarefa ou o objeto do ofício em ação (sentar na moto,
     amarrar uma rabiola, empinar, varrer a feira...).
Escreva embaixo de cada uma, em uma linha, a ideia de forma e o que ela diz da personalidade.
Pare e espere a escolha do criador.

4. REGRAS DE DESIGN
- UM exagero principal por personagem (manga enorme, cabelo grande, bota pesada, gola alta,
  corpo largo...). O resto sustenta esse exagero e descansa. Exagero sim, mas desenhável e
  consistente entre vistas.
- O tema (bairro, parceiro, lenda, ofício) tem que mudar UMA MASSA GRANDE do desenho (corte,
  peso, direção, recorte), não virar estampa ou detalhe pequeno.
- Repita um motivo com transformação (uma forma vira gola, depois fecho, depois mecha), sem
  colar o mesmo símbolo em todo lugar.
- Personagem e objeto nascem juntos: o objeto do ofício define proporção e pose.
- Roupa tem avesso: alças, fechos, costuras e o que muda ao tirar uma peça.
- Elemento de pipa presente (rabiola, vareta, linha, papel de seda, carretel), integrado à
  modelagem.
- Áreas quietas perto do rosto; contraste guardado para o rosto e para a assinatura.
- Compare com o elenco já aprovado (Kael, Tyler, Locutor, Sr. Assis e os outros em art/characters/):
  se o candidato repete topete alto, jaqueta aberta e pernas finas, mude a arquitetura, não a cor.

5. EXPRESSÕES COM PERSONALIDADE
Três expressões da MESMA cabeça, escolhidas pela personalidade (não sempre alegria, confiança
e surpresa). Inclua pelo menos uma expressão cotidiana: dúvida, distração, concentração,
desprezo, cansaço, riso contido. A sobrancelha e a boca mudam de verdade entre elas.

6. PRANCHA FINAL (só depois da escolha)
Layout da casa (skill, references/estilo-da-prancha.md): fundo branco, nome escrito à mão no
alto à esquerda, corpo inteiro em três quartos numa pose que mostre o gesto habitual (não a pose
genérica de apresentação), corpo inteiro de costas, três bustos de expressão em recorte redondo
e um estudo de linha. Acrescente o que a pessoa precisar: perfil, detalhe de fecho, pose sentada
ou com o objeto. Lados, fechos, cores e proporções iguais em todas as vistas.

7. PROIBIDO
- Anexar imagens do benchmark (Pokémon) ao gerador de imagem. Elas são estudo, não referência
  de geração.
- Desenhar qualquer personagem existente de outra franquia ou algo que lembre um específico.
- Texto, logo, assinatura ou marca d'água além do nome.
- Gradiente, textura pesada, luz de pôster, contorno grosso, acabamento 3D.
- Dizer que um teste "passou" sem ter feito o teste.

8. CONFERÊNCIA (escreva em revisao.md antes de entregar)
- Reconheço a pessoa sem o objeto, sem cor e sem o emblema?
- A cabeça difere do Kael além do penteado?
- Corpo e postura fazem uma escolha clara?
- O tema mudou alguma decisão grande?
- Há uma área dominante e áreas de descanso?
- O gesto mostra uma vida além da pose de apresentação?
- O traço e a cor são do Kael aprovado?
- Lados, fechos e proporções batem entre as vistas?
- O que foi testado e o que ainda é só proposta?

9. ARQUIVOS
art/characters/<id>/concept-v<n>/ com brief.md, exploracao.png (rodada 1), prancha.png
(rodada final), prompt.txt (prompts usados, com o papel de cada referência) e revisao.md.
Preserve as versões anteriores.
```

---

## Prompt curto para o gerador de imagem (prancha de exploração)

Use dentro do pedido quando o Codex for gerar a imagem da exploração:

```text
Imagem 1 é referência de ESTILO apenas (linha, cor, sombra); não copie o rosto, o cabelo nem o
corpo dela.
Prancha de exploração de personagem, fundo branco, três colunas, uma por proposta de forma para
<nome>, <idade>, <papel>, <personalidade em 3 palavras>. Em cada coluna, de cima para baixo:
contorno de corpo inteiro em preto chapado; a mesma figura em três tons de cinza; a cabeça em linha
fina sem cabelo e sem acessórios; uma pequena cena de uso com <objeto/tarefa>.
As três propostas diferem em altura, largura, comprimento dos membros, formato da cabeça e postura:
<proposta A em uma frase>; <proposta B em uma frase>; <proposta C em uma frase>.
Mangá 2D limpo, linha fina uniforme, sem gradiente, sem textura, sem texto além de "A", "B" e "C".
```
