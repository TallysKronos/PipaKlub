# Pegadas, altura e continuidade

## Modelo de apoio

Mantenha uma planta em coordenadas de terreno e uma função de altura. Para a grade local 64×32:

```text
screen_x = (u - v) * 32
screen_y = (u + v) * 16 - height_px
```

O suporte de cada prop vem da mesma função, não de offsets escolhidos pela aparência. Preserve os UVs na planta original para que elevar a superfície não desloque a pintura. Grade e altura em pixels são contratos configuráveis do projeto.

## Patamares e faces

Unir superfícies conectadas de mesma altura antes de desenhar paredes. Um material diferente não cria um degrau. Recortar as pegadas de rampas e depressões do piso que elas substituem; não desenhar um piso plano por baixo para tapar o defeito.

Topos, laterais e bases compartilham os mesmos vértices de contorno. Onde dois pisos se encontram na mesma cota não há parede. Faces expostas têm a diferença real entre alturas. Coordenadas espaciais/arco do contorno dão continuidade ao revestimento de parede; não reiniciar a pintura inteira em cada segmento.

Para Booleanas com arestas coincidentes, uma tolerância pequena em relação à escala pode evitar uma ponte residual. Use-a somente no cortador e sem mudar o desenho visível. Não criar saliências para esconder instabilidade numérica. Trate corretamente os anéis internos retornados por operações de polígonos; não preencher cada anel como se fosse solo. Um recorte aberto até o limite é apropriado apenas quando o desenho realmente pede uma saída aberta.

## Rampas

Uma rampa é uma superfície inclinada entre duas cotas; não uma textura de rampa sobre um muro. Construa o topo com altura interpolada na direção da subida. Suas extremidades coincidem exatamente com os dois pisos. Desconte a parede apenas no intervalo da boca.

As laterais são cunhas: a diferença para o solo adjacente chega a zero na ponta comum. Não usar um retângulo de altura constante sob toda a rampa, nem deixar faces finas penduradas sob a extremidade baixa. Elimine triângulos degenerados nas pontas.

No Jardim das Marés, exemplos concretos são +32→0 em três células e 0→−24 em 2,5 células. Esses números demonstram o contrato; não são dimensões impostas aos próximos mapas.

Confira cada boca, canto e lateral com material simples, depois com texturas sem ocupantes. Inspecione também a ordenação de profundidade: todos os objetos depois de todas as faces não é uma solução geral para personagens transitando por vários níveis.

## Poços, rios e depressões

Use um contorno medido para recortar o piso superior, fechar a margem e posicionar a superfície inferior. Projete a cota inferior para baixo em tela. O piso próximo deve ocultar a água/lava/areia que está atrás da margem; não deixar vazamento por baixo da parede.

O impacto de cachoeira fica na cota inferior, e o comprimento da queda inclui o rebaixo. Espuma pertence à camada da água e precisa ser ocultada pela margem próxima. Em rios que saem do mapa, não desenhar parede transversal fechando o fluxo nas saídas abertas.

Uma depressão submersa é diferença de terreno dentro da mesma coluna de água, não um segundo retângulo de “água sobre água”. Areia ou rocha no fundo podem usar tonalidade mais fria, mas a cor não substitui o rebaixo.

## Relevo suave e partes flexíveis

Dunas podem usar uma malha subdividida projetada de um campo contínuo de alturas. Conservar UVs nas coordenadas originais e apoiar props pela mesma função. Se o relevo precisa voltar a zero no limite, impor isso na altura, não ocultar a descontinuidade com vegetação.

Algas, flores e rabiolas precisam de malha com subdivisões e linha no pivô real. Peso zero na raiz/amarração e abaixo dela; aumentar o peso gradualmente até a parte livre. Fixar sombra de contato e suporte. Somente o topo flexível se move; não balançar todo o sprite rígido com a base solta.
