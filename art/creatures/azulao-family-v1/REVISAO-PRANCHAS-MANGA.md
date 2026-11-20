# Revisão das oito pranchas individuais

Ferramenta: image_gen integrada. PNGs copiados integralmente, sem repintura de arte por código. Prompts em cada pasta prancha-manga-v1; fonte, hash e dimensões em manifest-pranchas-manga.json.

## Correção do traço

O autor pediu recuperar o 2D mangá. As novas folhas usam a prancha aprovada do locutor como referência de acabamento: linhas finas cinza/carvão, cores chapadas menos saturadas e sombra curta, sem a moldura e o contorno preto pesado das silhuetas anteriores. A primeira nova folha, Azultor A, serviu também para alinhar as demais.

Isso é uma aproximação conferida visualmente, não prova de que o autor aprovou todas as folhas ou de que compartilham uma paleta de pixels pronta. A resolução é de concept; não são sprites finalizados.

| Prancha | O que foi conferido | Limites antes do rig |
| --- | --- | --- |
| **Azultor A** | Quatro patas em vista principal, duas asas separadas; frente de garras e traseira de cascos; crista dupla, azul/creme e nuvem. Bico voltou a dourado | O acabamento simplificado alongou a leitura das pernas em relação à silhueta A; confirmar proporção compacta no refinamento. Perfil tem sobreposição natural dos apoios, exigindo vista de construção antes do recorte |
| **Azulim** | Corpo pequeno e redondo, duas asas curtas, dois pés pequenos, crista dupla e rabiola curta. Perfil e costas explicam volume | A primeira geração foi bloqueada na moderação de saída e não produziu arquivo utilizável. A versão válida usa o prompt-retry, com descrição simplificada e apenas referências de criaturas. A proposta B ficou mais arredondada; ainda é escolha artística em revisão, não aprovação do autor |
| **Azulíneo** | Silhueta alta B preservada: pescoço, bico e pernas longos; duas asas e rabiola turquesa/azul; três expressões | O suporte de vareta nas asas ficou menos explícito que no concept original. Antes do Soulgen, definir quais nervuras realmente integram a estrutura e separar pernas das fitas |
| **Azulume** | Corpo compacto C, duas asas, dois apoios e leque com três painéis. O perfil e as costas mostram um único ponto de cauda | A leitura do leque como rabiola é uma solução desta prancha, não decisão prévia do autor. Confirmar como se conecta ao corpo sem acrescentar cauda duplicada |
| **Azulígero** | Nova proposta de corpo serpentino aviano: duas asas junto ao peito, duas patas traseiras e nenhuma dianteira; fitas separadas das patas. As três vistas diferem da ave alta de Arraia | Nova arquitetura ainda sem aprovação. Validar amplitude de curvatura do tronco, articulações da bacia e sustentação em repouso. Não copiar o rig de bípede vertical |
| **Azuláculo** | Corpo baixo e largo de planar, duas asas e dois pés; leque conectado, sem rabiola duplicada. Correção posterior manteve exatamente três lóbulos nas três vistas | A primeira folha acrescentou cinco lóbulos na vista principal/costas; foi preservada como rascunho e corrigida com image_gen. A ligação do leque e deformação do torso devem ser desenhadas em detalhe antes da animação |
| **Vela de Monção** | Mesmo corpo losangular da base sem pernas, duas asas em cobertura, rabiola e crista; borda e membranas dão leitura de proteção à chuva | Algumas superfícies mantêm planos facetados herdados da base; se o autor desejar um acabamento ainda mais plano, simplificar a pintura sem mudar a identidade. Não é estágio novo ou imunidade à água |
| **Vela de Alísio** | Mesmo corpo-base sem pernas, asas abertas/varridas com vãos e dupla fita de condução; distinta da cobertura da Monção | Verificar estabilidade dos painéis recortados em animação. Não tornar toda a asa uma membrana solta; suportes precisam manter conexão. Não é a rota B de Arraia disfarçada |

Todas têm três vistas e três estudos de cabeça; pequenas diferenças de desenho entre vistas geradas permanecem. O fato de haver um perfil não garante projeção ortográfica ou encaixe exato de recortes.

## Aprovação e escopo

- Escolha registrada: **Azultor A da folha de hipogrifos**.
- Arquiteturas Arraia B/C: previamente aprovadas, desenvolvidas aqui em pranchas separadas.
- Novos nomes, Azulim, Pandorgas B/C e Velas Especiais: propostas em revisão.
- Nenhum rig novo, animação, alteração de save, balanceamento, merge ou push.
- Não refazer as artes aprovadas do Azulão, Azulfazo e Azulfazo possuído por consequência desta galeria.

## Próximo passo de produção

Revisar estas interpretações e fixar as formas e proporções. Depois preparar vistas de construção e separação de peças completas — cabeça inteira para cada expressão, torso, membros, asas e rabiola com o fio. A spritelização/Soulgen vem depois da aprovação do desenho, preservando esta referência de traço.
