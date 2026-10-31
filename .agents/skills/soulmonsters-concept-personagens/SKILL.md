---
name: soulmonsters-concept-personagens
description: Projete e desenhe concepts de personagens humanos do Soulmonsters (pranchas com corpo inteiro, costas, expressões e estudo de linha) no traço autoral do dono, com design marcante no nível de um elenco de Pokémon. Use para criar protagonistas, rivais, campeões de bairro, vilões e NPCs, para redesenhar um personagem ou para planejar o elenco de uma região.
---

# Concepts de personagens do Soulmonsters

O traço já está decidido; o seu trabalho é o **design**. Um personagem bom aqui:

1. **parece desenhado pela mesma mão** do Kael e do Locutor (estilo);
2. **se reconhece de longe** pela silhueta e por um sinal de assinatura (forma);
3. **conta quem é** pela roupa: o parceiro Soulmonster, o bairro, o ofício e a personalidade (motivo);
4. **funciona no jogo**: lê em retrato, em miniatura de overworld e em batalha (uso).

Se um dos quatro falha, o personagem não está pronto.

## Leitura obrigatória

| Arquivo | Para quê |
| --- | --- |
| `../soulmonsters-character-art/references/kael-prancha-2026-10-30.png` | **autoridade de estilo e de layout**. Abra a imagem |
| `../soulmonsters-character-art/references/locutor-aprovado.png` | intensidade de roupa aprovada, mesmo layout |
| `../soulmonsters-character-art/references/kael-autoral.png` | desenho à mão do dono: origem do traço e das variações de cor |
| `../soulmonsters-character-art/SKILL.md` e `references/producao.md` | regras de traço, roupa funcional e produção |
| `art/benchmarks/bulbagarden-concept-2026-10-30/` | benchmark de concept art do dono (ver abaixo) |
| `documentation/historia/BIBLIA-DA-HISTORIA.md` | quem existe, papel, parceiro, o que é decidido e o que é proposta |
| [references/estilo-da-prancha.md](references/estilo-da-prancha.md) | o estilo decomposto em regras verificáveis e o layout da prancha |
| [references/design-de-personagem.md](references/design-de-personagem.md) | método de design "tipo Pokémon" adaptado ao nosso mundo |
| [references/elenco.md](references/elenco.md) | DNA de quem já existe e as vagas do elenco |
| [references/prompt-e-revisao.md](references/prompt-e-revisao.md) | prompt-base, papéis das referências, conferência e arquivos |

Prioridade em conflito: instrução explícita do dono > prancha do Kael de 30/10/2026 > Locutor V4 >
esta skill > o resto.

### O benchmark do dono

A pasta `art/benchmarks/bulbagarden-concept-2026-10-30/` reúne concept art oficial estudada pelo dono.
Na primeira vez, olhe todas as imagens e escreva `ANALISE.md` na própria pasta, com:
- o layout de prancha que se repete (vistas, expressões, anotações, cores);
- os princípios de design observados (silhueta, número de cores, sinal de assinatura, ligação com o
  tipo ou papel, linguagem de formas por personalidade);
- o que **não** se transporta para o nosso traço (acabamento, proporção, convenções da franquia).

O benchmark ensina princípios. Não copie rosto, roupa, símbolo, paleta inteira nem pose. Não anexe
imagens do benchmark como referência de estilo na geração: a referência de estilo é sempre a nossa
prancha.

## Fluxo por personagem

### 1. Brief (`art/characters/<id>/concept-v<n>/brief.md`)

Preencha o modelo de `design-de-personagem.md`: papel no jogo, idade, corpo, parceiro e tipo, bairro,
ofício, personalidade em três palavras, **sinal de assinatura**, **motivo do parceiro na roupa**,
paleta (2 principais + 1 acento + neutros), forma dominante, frase de fala que mostra a voz. Marque
cada item como decidido (bíblia ou dono) ou proposta.

### 2. Silhuetas (exploração)

Gere **4 a 6 silhuetas em preto chapado** do corpo inteiro, cada uma com uma ideia diferente de forma
(não só variações de cor). Junte numa folha `silhuetas.png`. Escolha a que passa melhor o teste da
silhueta e explique por quê no brief. Em personagem importante (rival, campeão, vilão, família),
mostre a folha ao dono antes de seguir.

### 3. Esboço de cor (2 ou 3 paletas)

Sobre a silhueta escolhida, 2 ou 3 variações de paleta, como o dono faz em `kael-autoral.png`.
Confira contraste entre o personagem, o parceiro e o fundo de batalha do bairro.

### 4. Prancha final

No layout padrão (`estilo-da-prancha.md`), usando a nossa prancha como referência de estilo e, num
redesenho, o personagem atual como referência de identidade (`prompt-e-revisao.md`).

### 5. Conferência e correção

Passe a lista de `prompt-e-revisao.md`. Corrija por edição dirigida (uma correção por vez, citando a
região da imagem) em vez de gerar tudo de novo; registre cada rodada. Teste da miniatura: reduza o
corpo inteiro para 64 px de altura e confira se ainda se reconhece.

### 6. Entrega

`brief.md`, `silhuetas.png`, `paletas.png`, `prancha.png`, `prompt.txt`, `revisao.md`. Atualize a
tabela de `elenco.md` com o estado (proposta, em revisão, aprovado). Commit
`Personagem <id>: <o que mudou>`.

## Limites

Você cria concepts. Não altera código do jogo, sprites em uso, rigs nem retratos aprovados. Pacote de
jogo (retrato com alpha, recortes de rig, spritesheet) é outra etapa, só quando pedida, seguindo
`producao.md`. Não muda nome, parceiro, idade ou papel decididos. Personagem novo é proposta até o dono
aprovar.
