# Riscaz · revisão da exploração

**Estado atual: direção A escolhida pelo dono; prancha de criatura concluída para avaliação visual, ainda não aprovada como design final.** Humano Rato continua sem aparência/idade escolhidas.

A seção “Consolidação de A” registra a entrega atual. O bloco abaixo conserva o histórico anterior à escolha de arquitetura.

## Histórico — exploração A/B/C antes da escolha do dono

## Inspeção anterior

Foi aberta a folha de parceiros de Rato. A opção 2 tem identidade clara (roedor-pipa carvão/creme/verde, incisivos-abas, orelhas de dobra, armação de bambu, rabiola e linha de vínculo), mas corpo e membros pareciam origami de rato genérico com palitos articulados. A nova exploração preserva a identidade e reorganiza proporções, gesto e massas de papel.

## Rodada 1 — folha A/B/C

Gerada com image_gen integrada. Únicas imagens anexadas: folha anterior, somente opção 2 como identidade; Kael como economia de traço/cor. Não houve imagem do benchmark na geração. A folha final foi aberta e examinada, não apenas aceita pelo prompt.

| Critério | Observado |
| --- | --- |
| Três soluções diferentes de forma | A baixa/larga em tensão; B compacta em losango com uma pata elevada; C longa/baixa em deslocamento. Não são recolorações |
| Continuidade de identidade | Carvão/creme/verde; focinho em cunha; incisivos de abas; papel dobrado; orelha assimétrica com V; mesma família de rosto animal |
| Membros vivos | Quatro membros por criatura, agora cobertos por volumes de papel. Gestos mais animais; varetas já não substituem toda perna |
| Pipa e armação | Grandes planos de papel e pequenos encontros de armação. Rabiola presa a nó traseiro; linha fina sai do peito e se distingue das fitas |
| Gesto/expressão | Olhar desconfiado e atento, boca econômica; B ergue uma pata sem virar humano fantasiado |
| Materiais/estilo | Contorno fino escuro, massas de cor chapada e planos de sombra; sem renderização plástica, textura pintada ou iluminação de pôster |
| Margens | Corpos, patas, orelhas e pontas das rabiolas inteiros dentro da folha 1536×1024, sem sobreposição entre opções |

## Recomendação

**A** é a recomendação após revisão comparativa: corpo baixo e largo preserva melhor a leitura de roedor; vela de ombro e gesto tenso mudam mais a forma original. **B** tem rosto/peito bem concentrados e atenção legível, mas fica mais perto do primeiro modelo e as orelhas altas podem lembrar coelho/mascote. **C** privilegia furtividade, porém o corpo comprido se aproxima de doninha e tem menos massa de roedor.

## O que ainda não está resolvido

- O gerador manteve facetas secundárias demais em algumas áreas de quadril/face. Após escolher uma arquitetura, reduzir para menos planos de cor e dobras maiores para aproximar ainda mais do mangá 2D limpo.
- A orelha em V está legível, mas a segunda orelha nem sempre parece claramente dobrada para trás. Fixar sua construção na etapa de vistas.
- O nó traseiro e duas fitas estão visíveis, mas a passagem dos dois canais de papel no corpo ainda é sugerida, não totalmente documentada. Precisa de construção de frente/costas após seleção.
- Não foram geradas vistas ortográficas, animação ou versão de 96 px. A folha é para escolher forma; não chamá-la de sprite ou asset pronto.
- Não se inferem tipo, raridade, evolução, habilidades, história de origem ou regras de combate. O acento verde evoca a linguagem visual do cerol; isso não implementa um poder.

## Entrega e limite

Presentes: `brief.md`, `exploracao.png`, `prompt.txt`, `revisao.md`, referência de identidade preservada. Código, assets em uso e outras pranchas permanecem intactos. Nenhum teste de jogo foi executado porque é revisão de concept, sem integração. Não houve push ou merge.

**Pergunta:** qual direção continuar, A (recomendada), B ou C? Só depois finalizar o desenho escolhido e retomar a definição humana de Rato.


## Consolidação de A — 30/10/2026

Dono: “Gostei da A também”. Seleção registrada como arquitetura A, sem inferir aprovação de Rato humano, tipo/poder, rig, sprite ou asset integrado.

### Rodadas da prancha

- **Rodada 2:** geração usando somente A da exploração como identidade/forma e Kael como economia de traço/cor. Prancha de criatura com três vistas e duas cabeças; nenhum layout humano imposto. Corpo baixo/largo e vela de ombro mantidos; membros de papel, sem esqueleto de varetas dominante.
- **Rodada 3:** correção dirigida das rabiolas. A primeira geração mostrava um S contínuo que não esclarecia duas fitas. Edição restrita à rabiola nos três corpos: uma fita longa em S e uma curta separada, ambas saindo do mesmo nó traseiro. Corpo, patas, face e estudos de expressão preservados. Original salvo em `prancha-rodada-01.png`.

### Conferência visual realizada na imagem entregue

| Item | Resultado |
| --- | --- |
| Arquitetura A | Baixa, larga e tensa, vela dorsal contínua com o ombro/flanco; não reintroduz B ereta ou C esguia |
| Anatomia | Quatro patas em cada vista corporal; volumes de papel e articulação animal; varetas limitadas a encontros estruturais |
| Rosto | Focinho em cunha, dois incisivos de abas, olho animal discreto e atento; não rosto humano do Kael |
| Orelhas | Duas por cabeça, uma com dobra em V/verde e outra mais recolhida; variação de obliquidade entre estudos permanece pequena e documentada |
| Rabiola | Duas fitas desiguais presas ao mesmo nó traseiro nas três vistas, corrigidas por edição dirigida; nada sai do peito como rabiola |
| Linha de vínculo | Fio fino preso ao peito, separado das duas fitas largas; não confundido com terceira rabiola |
| Cor e acabamento | Carvão/creme/verde preservados, contorno fino e sombra econômica; algumas facetas secundárias continuam, sem pretender acabamento de rig |
| Layout/margens | Branco, nome apenas; três corpos completos e duas expressões, sem patas, orelhas ou pontas de rabiola cortadas; 1536×1024 |
| Vistas | Frente 3/4 principal, traseira 3/4 e vista lateral de apoio. São referências desenhadas, não vistas ortográficas medidas |

### Diagnóstico a 96 px

Foi criada e aberta `qa/miniatura-96px.png`: seleção mecânica do corpo principal com rabiola, redução a 96 px de altura (133×96) e ampliação 3x, com comparação de cor e silhueta. Não houve repintura dos arquivos de produção. A massa baixa e larga, vela dorsal, focinho e curva da rabiola continuam legíveis. O V fino da orelha e os nós pequenos perdem definição nessa escala; a separação das duas fitas depende de manter o vão branco e precisará adaptação se houver sprite futuro.

**Limites:** o desenho documenta o design, mas não fixa pivôs, deformação de vela, voltas da rabiola ou padronização milimétrica da dobra de orelha entre ângulos. A simplificação de facetas, a continuidade da orelha e as conexões traseiras devem ser rechecadas ao criar assets animáveis; não se declara rig pronto. Não foram gerados animação, atlas, tipo, evolução ou habilidade. Nenhum teste de jogo foi executado, porque não houve mudança de runtime.

### Entrega atual e próximo passo

`prancha.png`, exploração anterior, brief, registro completo de prompts, revisão e diagnóstico 96 px presentes. Paleta existente foi preservada, portanto não se gerou uma folha de recolorações desnecessária. O dono aprovou A; a nova prancha ainda está em revisão visual.

Próxima decisão pendente é **Rato humano: A28/B40/C55/D48**, com confirmação dos traços físicos correspondentes. Nenhuma opção humana foi presumida a partir de Riscaz. Grampo não iniciado; sem push/merge ou alteração do jogo.
