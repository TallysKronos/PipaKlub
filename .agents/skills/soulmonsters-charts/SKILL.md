---
name: soulmonsters-charts
description: Pesquise e crie charts evolutivos e concepts de famílias Soulmonsters a partir de um mon existente, com história de maturidade, ramificações e transformações por materiais na direção 45% criatura, 45% pipa e 10% pixel/2D mangá. Use para projetar ou revisar famílias; integração e animação são etapas separadas.
---

# Charts de Soulmonsters

Crie uma família que conte uma história reconhecível: cada forma tem personalidade, motivo para existir, especialidade e construção de pipa viva. O chart mostra relações e consequências; os concepts tornam essas relações visíveis.

## Começar pelo mon pedido

Receber só o nome é suficiente para começar. Busque com `rg` em `art/soulgen`, `art/creatures`, manifestos e documentação, resolvendo aliases sem renomear IDs existentes. Abra a arte atual e as variantes aprovadas; leia registros de decisão e trechos pertinentes de `documentation/historia/BIBLIA-DA-HISTORIA.md`. Uma versão com prompt mais recente não supera uma edição manual aprovada.

Leia [references/pesquisa-e-historia.md](references/pesquisa-e-historia.md) para pesquisa, maturidade, vocabulário e construção narrativa. Leia [references/direcao-e-revisao.md](references/direcao-e-revisao.md) antes de definir anatomia ou gerar imagem. Para salvar chart, fontes e entregas, use [references/entrega.md](references/entrega.md).

Separe no brief: **definido pelo autor/cânone**, **observado na arte**, **proposta** e **desconhecido**. Se duas fontes locais conflitam, registre o conflito e priorize a decisão explícita mais recente do autor. Não escreva uma proposta na bíblia como fato.

## Núcleo autoral

- **45% criatura:** corpo vivo, expressão, temperamento, ação e maturidade.
- **45% pipa:** papel tensionado/dobrado, varetas, nós, linha e rabiola integram cabeça, torso e membros. Não basta decorar asas de um animal.
- **10% pixel/2D mangá:** planos de cor nítidos, sombra em blocos, expressão mangá e contorno escuro com degraus seletivos. Ilustração gerada não é automaticamente pixel art técnico.

Os percentuais expressam equilíbrio de direção, não uma métrica técnica. A pipa pode assumir muitos corpos, sem exigir losango, bico, remendo ou nuvem em todos. Se uma forma vira equina, o rosto também é equino. Preserve parentesco por um conjunto seletivo de cores, padrões, construção, detalhes ou comportamento.

## Fluxo de criação

1. **Identidade e pesquisa.** Estude a base e referências externas pertinentes; escreva o que cada caso ensina e o que não deve ser transportado. Consulte fontes oficiais atuais em vez de reutilizar lore de memória. A pesquisa deve orientar o brief, sem virar um catálogo indiscriminado.
2. **História da família.** Escreva uma frase para o amadurecimento da linha e outra para cada alternativa. Evolução costuma lembrar bebê/criança/jovem/adulto, mas a distribuição por estágio é proposta até ser definida para aquela família. Não confunda amadurecer com acrescentar chifres.
3. **Chart proposto.** Organize apenas os caminhos que têm motivo próprio. Distinga evolução de estágio, especialização, material raro, Entrelaço e estado narrativo. Nomeie o motivo de cada ligação e suas incógnitas. Use o vocabulário aprovado, sem copiar o número de formas do Azulão.
4. **Brief por forma.** Defina identidade herdada, anatomia de destino, maturidade, verbo principal, parte do corpo que torna a ação possível, personalidade, limitação proposta e papel na história. Uma mudança estrutural forte precisa de parentesco; continuidade não significa copiar o mesmo rosto.
5. **Piloto e arte.** Comece pela transformação que melhor testa a família. Se a direção ainda estiver aberta, mostre poucas miniaturas de arquiteturas realmente distintas. Se já estiver escolhida, desenvolva-a diretamente. Gere um mon por chamada com a ferramenta de imagem disponível, seguindo a skill `imagegen`. Abra imagens locais antes de usá-las. Referências externas estudadas não entram como inputs de geração.
6. **Conferência e continuidade.** Compare base e evolução; confira cabeça, membros, asas, raízes e rabiola completa, além de ação e acabamento. Corrija uma falha concreta por edição dirigida. Se a tentativa repete o erro, recue ao brief em vez de fazer um lote inteiro na direção errada.
7. **Entrega.** Salve chart navegável/documento, briefs, fontes, imagens, prompts e revisão. Mostre o resultado e suas decisões. Registre aprovações com escopo. Não declare peças animáveis, pixel art sustentável ou integração sem realizar essas etapas.

Adapte a sequência ao pedido: “estude” entrega pesquisa; “proponha um chart” não exige produzir todas as artes; “crie o chart e os designs” inclui desenvolver as artes autorizadas. Não pare no plano quando o usuário pediu execução. Não gere uma grande família de pranchas finais antes de conferir o primeiro piloto. Não imponha aprovação a cada passo se o usuário já autorizou continuar; pergunte apenas quando faltar uma decisão que muda identidade canônica ou a direção não puder ser resolvida como proposta identificada.

## Aprendizado concreto

Consulte [references/casos-do-azulao.md](references/casos-do-azulao.md) ao calibrar a primeira família ou entender as falhas anteriores. É uma coleção de decisões e exemplos, não um molde obrigatório para todos os mons. A arte própria atual do mon pedido tem prioridade de identidade.

## Escopo e qualidade

O padrão é pesquisa + concept + documentação. Preserve artes aprovadas e rigs editados pelo autor. Criação de chart não autoriza alterar gameplay, save, atribuir montaria, escolher item de obtenção definitivo, integrar, fazer merge ou publicar. Se o pedido também incluir Soulgen/integração, trate como etapa explícita com seus contratos reais.

Use `scripts/validar_chart.py` para conferir IDs, relações, estágios e referências locais de um chart no formato desta skill; ele não mede originalidade, qualidade de desenho, lore ou diversão. Não use o teste rígido de 11 nós do piloto Azulão para validar outras famílias.
