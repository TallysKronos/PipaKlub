# Prompt, referências, conferência e arquivos

## 1. Papéis das imagens de referência

Anexe à ferramenta de imagem nesta ordem e diga o papel de cada uma no prompt:

1. `kael-prancha-2026-10-30.png`: **ESTILO e LAYOUT** (sempre).
2. `locutor-aprovado.png`: **ESTILO** de apoio e intensidade de roupa (sempre que a roupa for
   expressiva).
3. Arte atual do personagem: **IDENTIDADE** (só em redesenho; preserva rosto, pele, idade, corpo,
   cabelo e objeto).
4. A silhueta escolhida e a paleta aprovada: **FORMA e COR** do novo personagem.

Nunca anexe imagens do benchmark de outra franquia como referência de geração.

## 2. Prompt-base da prancha

```text
Imagem 1 é a referência principal de ESTILO e de LAYOUT. Imagem 2 é apoio de estilo para roupa
expressiva. [Imagem 3 preserva apenas a IDENTIDADE da pessoa.] [Imagem 4 dá a SILHUETA e a PALETA.]

Desenhe uma prancha de concept de personagem no mesmo layout da imagem 1: fundo branco liso, nome
"<Nome>" escrito à mão em cinza-escuro no alto à esquerda com um traço curto sublinhando; corpo
inteiro em três quartos à esquerda, <pose de apresentação>; corpo inteiro de costas no centro, na
mesma altura; à direita, três bustos de expressão em recorte redondo (<emoção 1>, <emoção 2>,
<emoção 3>), com traços de movimento só nas emoções explosivas; embaixo à direita, um estudo de linha
do busto sem cor.

Personagem: <idade>, <corpo>, <pele>, <cabelo>. Personalidade: <3 palavras>; forma dominante <forma>.
Sinal de assinatura: <peça>, visível em todas as vistas. Motivo do parceiro <espécie>: <como vira
modelagem de tecido e silhueta>. Elemento de pipa: <qual e onde se prende>. Objeto do ofício:
<objeto, como é segurado ou preso>. Paleta: <principal 1>, <principal 2>, acento <acento> em
<1 a 3 lugares>, neutros <neutros>.

Mesmo acabamento da imagem 1: linha fina escura e uniforme, cor chapada levemente suave com uma
única sombra dura discreta por material, olhos ovais grandes com um brilho, nariz e boca simples,
membros longos e limpos, mãos legíveis, calçado em escala humana. Assimetrias no mesmo lado do corpo
nas duas vistas. Sem gradiente, sem textura, sem iluminação de pôster, sem contorno grosso, sem
acabamento 3D. Sem logo, assinatura, marca d'água ou qualquer texto além do nome.
```

Folha de silhuetas: "4 a 6 figuras de corpo inteiro em preto chapado sobre branco, mesma altura,
cada uma com uma ideia de forma diferente para <brief resumido>; sem detalhes internos".

## 3. Conferência da prancha (`revisao.md`)

Estilo (lado a lado com a prancha do Kael):
- [ ] Linha, rosto, olhos, cor chapada e sombra parecem da mesma mão?
- [ ] Layout igual: nome, frente, costas, três bustos redondos, estudo de linha, fundo branco?

Design:
- [ ] Teste da silhueta: reconhecível em preto chapado e diferente de todo o elenco?
- [ ] Teste da miniatura: reconhecível com o corpo a 64 px de altura?
- [ ] Assinatura presente e igual em todas as vistas?
- [ ] Motivo do parceiro lido na modelagem, sem virar fantasia de mascote?
- [ ] Paleta dentro de 2 principais + 1 acento + neutros?
- [ ] O papel (ofício) se lê em um olhar?

Construção:
- [ ] Penteado, assimetrias, costuras, cores e acessórios coerentes entre frente, costas e bustos?
- [ ] Tecidos saem de costuras reais; tiras e caudas presas em algum lugar; objetos com eixo e
      empunhadura; mãos com dedos certos; pés completos?
- [ ] As três expressões são deste personagem e leem em tamanho de retrato?
- [ ] Nada de texto extra, logo, marca d'água, paleta desenhada ou parte cortada?

Registre cada rodada de correção: o que estava errado, a edição pedida, o resultado.

## 4. Arquivos

```text
art/characters/<id>/concept-v<n>/
  brief.md
  silhuetas.png
  paletas.png
  prancha.png
  prompt.txt      (prompts usados, na ordem, com o papel de cada referência)
  revisao.md      (conferência, rodadas de correção, pendências)
```

Preserve `concept-v<n-1>`. Imagens usadas pelo projeto ficam dentro do repositório. Imagens do
benchmark não entram em pastas de produção.
