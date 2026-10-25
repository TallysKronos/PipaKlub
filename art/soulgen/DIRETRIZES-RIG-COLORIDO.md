# Soulgen · diretrizes de arte recortada, animação e expressões

Referência aprovada pelo usuário em 2026-10-21: Carcará, em `keys/carcara/color-rig/`. Este documento registra a direção aprovada para repetir o processo em outras criaturas. O exemplo foi revisado em prévia local; ainda não representa integração ao jogo.

**Revisão de arte de 24/10/2026:** leia primeiro [Direção de arte — padrão Carcará](DIRECAO-ARTE-CARCARA.md). O Carcará governa também olhos discretos, anatomia de espécie, papel facetado e remendos. Os rigs do lote `basic-color-v1` têm verificação técnica, mas precisam de revisão artística; seus olhos grandes e acabamento polido não definem o estilo aprovado. As regras de animação abaixo continuam válidas.

## 1. Identidade e acabamento

- Preserve o desenho aprovado, a paleta original, os detalhes de papel e o volume da ilustração. Não reduzir as cores ou substituir a arte por um placeholder procedural para facilitar animação.
- Todos os Soulmonsters incorporam anatomia de pipa: vela, varetas, dobras, asas, nós ou rabiola participam da construção do corpo. A linha é o método de manifestação. Não basta acrescentar uma pipa decorativa a um animal comum.
- Registre espécie, personalidade, silhueta, vista, orientação, proporções e materiais antes da produção. Uma imagem define identidade; uma referência de estilo não autoriza trocar essa identidade.
- Preserve contorno, planos de cor, origem da luz e densidade de detalhes em todas as partes e expressões.
- Variante noturna ou monocromática é uma entrega adicional quando pedida. Não substitui a apresentação principal colorida.
- O rig colorido não impõe limite de 15 cores, alpha binário, textura de 96×96 ou escala final de 64 px. Essas restrições pertencem ao pipeline anterior de pixel art.

## 2. Planejamento de camadas

Separe as partes que precisam de movimento independente. Para o Carcará: corpo, asa distante, asa próxima e rabiola. Outras criaturas podem exigir braços, orelhas ou várias velas. Não decompor sem necessidade: cada peça adicional cria uma articulação a revisar.

Antes de gerar, defina:

| Campo | O que deve estar registrado |
|---|---|
| Fonte | PNG aprovado e seu papel de referência |
| Vista | Ângulo e direção de olhar, mantidos em todas as partes |
| Parte | Nome semântico e função anatômica |
| Recorte | Retângulo real na fonte, sem fragmentos de outro slot |
| Destino | Retângulo da parte na pose montada |
| Pivô | Ombro, laço ou outra articulação real |
| Profundidade | Ordem da parte em relação ao corpo |
| Conexão | Região que deve permanecer coberta na raiz da articulação |
| Movimento | Amplitude e limites compatíveis com essa anatomia |

Não confiar na grade aparente de uma imagem gerada. Medir recortes reais: uma parte pode atravessar a divisão imaginada de um atlas. O resultado final precisa ter coordenadas explícitas.

## 3. Geração e fontes

1. Inspecione a referência aprovada antes de usá-la na geração.
2. Gere partes relacionadas como uma família, mantendo as mesmas cores, luz, escala e perspectiva.
3. Peça PNG com transparência real e margem suficiente. Não pedir texto, rótulos, grade ou amostras de cor dentro dos recortes usados pelo jogo.
4. Peça raízes completas nas peças articuladas, sem vazios que se abram ao girar. A raiz deve sobrepor a região anatômica de conexão.
5. Guarde o PNG original da geração e o prompt completo. Não substituir a fonte por uma exportação redimensionada.
6. Faça recorte, registro e composição de forma reproduzível. Não redesenhar olhos ou anatomia por código como substituição de uma arte solicitada.
7. Se a fonte não permitir uma articulação limpa, corrija a peça na arte antes de compensar com movimento ou efeitos.

O exemplo aprovado usa `image_gen`. `source/layers-generated.png` contém as partes originais; `color-rig/expressions-generated.png` contém o estudo facial gerado a partir do recorte real do corpo. Prompts e referências estão nas pastas correspondentes.

## 4. Montagem e transformações

- Use um sistema comum de coordenadas para todas as partes. No exemplo, 96 unidades são uma convenção de montagem; as texturas mantêm a resolução original.
- Desenhe a fonte diretamente por recortes; evite destruir detalhes com redução prévia para sprites pequenos.
- Aplique deslocamento e inclinação comuns do corpo antes das rotações locais. Depois rotacione cada asa em seu ombro e a rabiola em seu laço.
- Não recalcular o pivô pelo bounding box de cada quadro. Ele representa a anatomia, não o contorno variável da peça.
- Não arredondar posição/ângulo a pixels inteiros em cada atualização do rig colorido. Isso pode produzir saltos nas bordas.
- Use uma política de amostragem coerente com a fonte e confira o resultado na escala de exibição. O exemplo colorido usa smoothing alto no Canvas; nearest-neighbor pertence ao ensaio pixel art anterior.
- Ordem do Carcará: rabiola → asa distante → corpo com sua face → asa próxima. A ordem deve ser definida pela anatomia de cada espécie.
- Evite fendas nas articulações, partes soltas, asas cruzando os olhos e fitas que pareçam pernas. Inspecione os extremos, não só o repouso.
- Escala e centro de enquadramento devem permanecer fixos ao trocar uma animação ou expressão.

## 5. Movimento e tempo

| Ação | Leitura esperada | Regra de reprodução |
|---|---|---|
| Repouso | Flutuação leve, pequenas compensações nas asas e rabiola | Ciclo contínuo, início e fim compatíveis |
| Voo | Batida de asas clara, corpo acompanhando o esforço | Ciclo contínuo sem salto de pose |
| Golpe | Preparação, avanço/impacto e recuperação | Ação única com instante de impacto declarado |
| Dano | Recuo breve e recuperação controlada | Ação única, sem tremor infinito |
| Vitória | Gesto orgulhoso ou alegre e retorno ao repouso | Ação única, salvo decisão explícita do jogo |

- Use interpolação contínua e aceleração/desaceleração deliberadas. Asas não devem trocar de posição em passos bruscos causados por poucos quadros discretos.
- O corpo lidera a ação; partes secundárias acompanham sem perder sua conexão. Não movimentar todas as peças com a mesma amplitude apenas para demonstrar que existem camadas.
- Registre duração em segundos ou outra unidade explícita, evento de impacto e política de loop.
- Repouso e voo devem fechar tanto em posição quanto em andamento visual. Teste o encontro entre fim e início.
- Ações não contínuas precisam terminar em uma pose estável. A galeria de revisão pode repeti-las com intervalo; o comportamento do jogo não deve ser inferido dessa galeria.
- Não depender da taxa de quadros do monitor para determinar velocidade. Use tempo decorrido e resete a referência temporal após aba oculta/pausa.

## 6. Expressões sem glitches

### Invariantes

O rosto neutro e as variantes devem compartilhar exatamente o tamanho da textura, a posição do corpo, a silhueta e o alpha. Bico, capuz, remendos, armação, iluminação externa e encaixes não mudam para simular uma expressão.

Delimite janelas fixas para olhos/sobrancelhas. Registre as imagens geradas por marcos do rosto, não pelo centro aproximado do slot. Componha apenas essas regiões sobre um corpo canônico. O alpha final deve vir do corpo original.

No exemplo, `prepare-faces.py` registra as regiões geradas, suaviza apenas as bordas internas dessas janelas e verifica que todo pixel externo e todo alpha continuam idênticos. As texturas faciais resultantes são corpos completos alinhados, não recortes retangulares sobrepostos em tempo de execução.

### Estados

- **Neutro:** leitura calma do personagem; usado no repouso, voo e recuperação.
- **Golpe:** olhar firme, olhos mais estreitos e sobrancelhas baixas, sem mudar a identidade.
- **Dano:** olhos apertados; expressão breve, compatível com o recuo.
- **Vitória:** olhos felizes ou outra expressão coerente com a personalidade.
- **Piscada:** opcional. Só acrescentar quando houver uma variante registrada tão bem quanto as demais.

Defina janelas temporais por ação, incluindo a volta ao neutro. Não herdar os segundos de outra criatura sem avaliar sua duração. No Carcará: golpe 0,22–1,65 s; dano 0,03–0,72 s; vitória 0,25–2,08 s.

Não trocar aleatoriamente a face por quadro, piscar a textura do corpo, sobrepor dois pares de olhos ou esconder problemas de alinhamento com flashes. A troca pode ser discreta se geometria e papel de fundo estiverem registrados; não exige crossfade que produza olhos duplicados.

## 7. Prévia obrigatória

Entregue uma prévia local ou independente que use as mesmas fontes, transformações e tempos da entrega. Deve permitir:

- Ver o personagem inteiro em escala útil e comparar com uma exibição pequena.
- Selecionar cada animação, pausar, reproduzir e reiniciar uma ação.
- Reduzir a velocidade e percorrer o tempo para inspecionar impacto e extremos.
- Alternar fundo claro e escuro para revelar halos, recortes e alpha incorreto.
- Identificar a ação, o instante e a expressão ativa.

Não tratar uma folha estática como prova de animação estável. Não usar apenas GIF com fundo opaco para validar transparência. Na entrega aprovada, a prévia compõe os PNGs transparentes diretamente no Canvas e o HTML inclui suas fontes para abrir sem serviços externos.

## 8. Auditoria técnica e visual

### Verificações automatizadas

- Arquivos existem, dimensões e recortes correspondem às fontes reais.
- Pivôs, âncoras, retângulos e valores interpolados são finitos e usam a unidade declarada.
- Ciclos fecham sem salto de pose e ações retornam ao estado de recuperação definido.
- Expressões correspondem às janelas de ação e retornam ao neutro.
- Variantes faciais têm alpha idêntico; pixels fora das janelas faciais são idênticos ao corpo canônico.
- Renderizar uma expressão usa a mesma geometria de corpo e não acrescenta outra face por cima.
- Se houver exportação raster, verificar margem, cortes, tempos, pivôs, frame de impacto e atlas da exportação real.

### Inspeção visual

Revise cada ação inteira e seus extremos nas duas cores de fundo. Procure fendas, mudanças de volume, asas atravessando rosto, rabiola soltando do laço, tremor de borda, duplicação de olhos, retângulos de cor, recortes de outro slot, salto no loop e atraso de expressão em relação ao impacto.

Verifique leitura na escala real de jogo antes de integrar. Testes matemáticos e igualdade de alpha ajudam, mas não substituem avaliação estética ou validação no consumidor final.

## 9. Entrega e rastreabilidade

Cada espécie deve manter, em pasta própria:

- Brief e referência aprovada, com a revisão/formato atual declarados.
- Fontes originais geradas, ferramenta usada e prompts completos.
- Recortes, ordem de desenho, pivôs, âncoras e unidades em código ou manifesto legível.
- Texturas faciais registradas e máscara/janelas de registro.
- Definição de ações, durações, impacto e reprodução.
- Scripts de preparação e de construção da prévia.
- Prévia independente, testes relevantes, relatório técnico e evidência visual.
- Limitações, estado de aprovação, integração e publicação descritos separadamente.

Uma revisão que altera o formato deve atualizar o índice e o brief para evitar que outra pessoa aplique as restrições antigas por engano. Preserve a versão anterior como histórico, mas indique claramente qual é a preferida.

## 10. Integração e limites

O rig aprovado usa a engine própria JavaScript/Canvas 2D. Não exige troca de motor. Antes de integrar, confira escala, câmera, ordem de profundidade, consumidor de animações e eventos de dano reais.

O rig de recortes preserva uma vista. Virar completamente, mudar a perspectiva ou expor uma parte escondida exige desenho adicional; não esticar a vista existente para fingir outra anatomia. Penas individuais, deformações segmentadas e física de várias fitas são extensões possíveis, não funcionalidades já entregues.

O exemplo aprovado é uma prévia animada em cores. Não é ainda um atlas substituto integrado no combate. O linter de 15 cores continua útil somente para o formato pixel art anterior. Publicação no Git não significa deploy ou integração automática.

## Junções de papel, sem encaixes de brinquedo

Não gerar bocas de tubo, cavidades pretas, aros de corte, tampas circulares ou pinos nas raízes móveis. Uma raiz fechada é uma continuação sólida do papel e deve entrar sob a peça vizinha com folga para a amplitude da animação. Não é a tampa de um cilindro. Nós de corda participam da estrutura da pipa, não substituem articulações.

Revisar as fontes isoladas e a montagem sobre fundos claros e escuros. Pivôs coincidentes e atlas sem cortes não provam que a anatomia está unida: cavidades podem estar pintadas na própria arte. Checar pescoço, raiz da cauda e topo de cada membro em todas as ações. Não esconder defeitos com remendos decorativos; corrigir a fonte e a sobreposição.
