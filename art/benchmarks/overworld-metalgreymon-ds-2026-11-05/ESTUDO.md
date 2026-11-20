# MetalGreymon — estudo da referência de overworld

Referência enviada pelo autor em 05/11/2026. Inspeção direta do PNG e ampliação nearest-neighbor; não é uma especificação oficial de produção do jogo. Cadastro externo consultado apenas para confirmar identificação: https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/48322/ . O cadastro contém uma prancha maior que o recorte do autor; não são o mesmo arquivo. Direitos da referência pertencem aos respectivos titulares; não usar pixels dela nos assets do projeto.

## Medições do arquivo fornecido

- PNG 144×162 RGBA, todos os pixels opacos.
- 18 cores distintas incluindo o fundo azul sólido #7bc6ff; portanto 17 cores de primeiro plano nesta imagem.
- Recorte de diagnóstico [35,0,72,40]: a primeira pose ocupa aproximadamente 31×36 px incluindo chifres, asas e extremidades. Não confundir essa caixa com uma célula oficial do atlas.
- O PNG não fornece duração de frames. Não derivar FPS ou ordem oficial dos arquivos a partir de uma imagem estática.
- Cabeça e tronco não foram segmentados por máscara semântica; proporções anatômicas abaixo são estimativas visuais, não medidas exatas do original.

## Construção visual

### 1. Reproporção, não redução

A cabeça protegida pelo capacete e o focinho projetado ocupam uma grande parcela do núcleo corporal. Tronco encurtado, pescoço praticamente oculto, pernas pequenas e pés largos aproximam cabeça, ombros, quadril e chão. Asas e cauda ampliam a silhueta sem alongar o eixo corporal. A cabeça não é uma esfera kawaii: focinho, chifres, plano do elmo e expressão continuam específicos da criatura.

### 2. Hierarquia de identidade

Primeiro: elmo/focinho/chifres e grande braço metálico. Segundo: asas azuis, crista vermelha e corpo laranja. Terceiro: passos e detalhes menores. A garra é uma exceção deliberada à simplificação do corpo: é também identidade. Portanto não interpretar a regra como cabeça detalhada e todo o resto sem detalhe.

### 3. Detalhe com função

Os agrupamentos claros do elmo descrevem testa, ponte do focinho e plano lateral. Sombras separam elmo de corpo; poucos pixels bastam para o rosto porque a forma do focinho já informa a espécie. Não há dependência de olhos enormes ou muitos pixels de expressão. A garra usa agrupamentos metálicos maiores e contraste; o torso mantém massas laranjas mais econômicas. Asas recortadas e azuis são reconhecíveis por forma e cor antes das nervuras.

### 4. Sobreposição e profundidade

Cabeça na frente do torso, crista e asas atrás, grande garra sobre a barriga, pernas parcialmente ocultas. O ponto de vista elevado mostra topo do elmo e do corpo enquanto comprime pescoço e abdome. O tronco não vira um retângulo frontal longo. Bordas internas servem para separar materiais/planos, não contornam cada pecinha igualmente.

### 5. Maturidade preservada

A compressão anatômica é grande, mas o monstro mantém focinho pesado, olho estreito, chifres e membro ameaçador. Cabeça maior não implica bebê; o rosto adulto sobrevive à estilização. Isso interessa particularmente aos cavaleiros de Soulmonsters.

### 6. Cor e contorno

Paleta medida restrita; vários materiais compartilham tons escuros. Metal cinza, corpo laranja, asas azuis e crista vermelha formam blocos diferentes. A borda usa escuros e não depende de um fio preto grosso em todas as regiões. Pequenos claros modelam formas prioritárias; não se distribuem como ruído por todas as placas. Não há gradiente de renderização.

### 7. Animação

As sequências visíveis preservam chifres, focinho e massas principais enquanto pés/garra/asa variam. O corpo inteiro não é redesenhado como um novo personagem em cada quadro. Cabeça funciona como âncora de reconhecimento, com mudanças de posição/oclusão coerentes. Não afirmar que o elmo é idêntico pixel por pixel entre todos os frames ou vistas sem comparação específica. Tampouco afirmar espelhamento perfeito: a assimetria do braço exige atenção.

## Diferença para o Alvacordo produzido

O piloto manual tinha cabeça relativamente pequena e corpo comprido, típico de uma miniatura do concept. A prancha gerada melhorou focinho/gola, mas ainda tentou conservar divisões e detalhes equivalentes por todo o corpo. A redução para 64×64 criou concentração de ruído e pequenas diferenças de desenho entre frames. Não basta aumentar a resolução ou quantizar as cores: precisamos decidir uma anatomia de overworld antes de gerar a caminhada.

## Direção proposta para um próximo teste de Alvacordo

Canvas 64×64; criatura ocupando cerca de 52–58 px de altura com respiro. Cabeça anatômica de aproximadamente 18–22 px de altura incluindo as orelhas, gola como massa separada; núcleo de cerca de 2,5–3 cabeças. Estimativas para teste, não medidas do MetalGreymon nem padrão obrigatório para todo o elenco.

- Cabeça maior, focinho estreito e projetado, orelhas triangulares de cão e olhos adultos. Evitar cabeça arredondada e olhos infantis.
- Gola branca pontuda como moldura do rosto; dois ou três recortes grandes em vez de muitas mechas.
- Torso curto; janela de pipa em petróleo e dois tirantes vermelhos legíveis. Omitir frisos secundários.
- Quadril e pernas compactos; pés largos com leitura de apoio. Não esconder encaixes.
- Preservar ambos os arcos de antebraço como assinatura; separar os suportes e encurtar a distância entre mão e ombro.
- Cauda com duas pontas legíveis, sem roubar a prioridade do rosto.
- Gerar primeiro uma pose-mestra com essas proporções; aprovar a leitura em 1× antes da folha animada. Derivar frames dessa pose, corrigir cada rosto para evitar troca de identidade.

Princípio: **ampliar identidade, comprimir anatomia, simplificar informação secundária**. A proporção 45% criatura /45% pipa /10% acabamento continua conceitual; não significa dividir fisicamente a área do sprite nesses percentuais.
