# PIP-85 — Parque

Dois estudos de acabamento derivados das plantas revisadas na PIP-81. Ainda não são fundos de navegação nem kits aprovados. Fontes, prompts e referências preservados nesta pasta.

## Direção proposta

- Jardim das Pipas: parque cuidado pelos moradores; coreto com telha cerâmica, pilares creme e ferragens azul-petróleo; flores concentradas junto às árvores. Piso aberto no nível do terreno.
- Clareira do Papel: vegetação menos aparada, capim de encontro com silhueta alta e escura, pequenos papéis e rabiolas presos em alguns galhos. Sem coreto.
- Mesma luz do alto à esquerda, contorno azul-escuro e grandes massas de cor do Bairro. Capim com touceiras irregulares, sem repetir o símbolo ^; caminho de terra amplo e sem grade de riscos.

## Revisão dos estudos

A leitura artística distingue as duas áreas, mostra os dois grupos de mato do Jardim e os três da Clareira e mantém o terreno plano. Porém a geração deslocou troncos e móveis, acrescentou bancos e deslocou a placa do Jardim para a saída leste. O coreto também precisa de uma construção técnica que confira seus cinco pilares. Não foi atingida nem declarada a tolerância de 4 px exigida para um paintover final alinhado.

As plantas continuam sendo a autoridade. Os JSONs `*-brief.json` guardam hashes, pegadas, eventos e centros projetados exatos. O kit deve ser montado nesses pontos; não se deve mudar navegação para acomodar as imagens. `revisao.html` permite sobrepor a planta ao estudo sem deformá-lo.

## Produção e integração — atualização de 27/10

O kit foi produzido em `art/overworld/kits/parque/` e integrado à prévia Godot. O desenho agora usa os pontos da planta, em vez das posições aproximadas destes estudos. O bloqueio do coreto foi convertido em cinco objetos de pilar. A revisão nativa e seus limites estão em `documentation/overworld/parque/README.md`. A lista abaixo registra o plano inicial; acabamento alinhado do conceito e aprovação final permanecem pendentes.

## Plano inicial

1. Refinar o conceito alinhado usando as posições dos briefs; manter apenas os móveis previstos. A expressão visual dos estudos é o alvo de acabamento, não sua geometria aproximada.
2. Cinco materiais, quatro amostras de 64×32 cada; oito pares de transição com 16 máscaras por par. Textura neutra de grama e touceiras de encontro em camada própria com animação de vento separada.
3. Coreto 4×4 com cinco pilares e área interna livre; reaproveitar árvores a/b/florida, banco, poste, placa-mapa, vaso e lixeira do kit comum.
4. Resolver a divergência de colisão: a planta atual marca a pegada inteira do coreto como bloqueada, enquanto a tarefa pede só cinco sólidos. Conferir o consumidor e a passagem antes de alterar esse contrato.
5. Integrar e capturar as duas áreas no Godot a 1280×720, incluindo leitura do capim no enquadramento do Steam Deck. Isso ainda não foi realizado nesta etapa de conceito.

Nenhuma alteração de campanha, encontros ou saves. O novo kit é consumido somente pela prévia independente. Nenhuma suíte de testes executada. O status da tarefa é In Progress; os critérios de aceite permanecem abertos.
