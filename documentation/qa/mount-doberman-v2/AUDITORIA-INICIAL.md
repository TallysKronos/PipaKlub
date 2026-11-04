# Auditoria visual do cavaleiro — 01/11/2026

**Resultado: não aprovado como encaixe final.** A composição estática funciona tecnicamente, mas ainda não é uma boa base para gerar os ciclos definitivos. Escopo: imagens `directional-fit.png` e `trail.png`, comparadas com o manifesto e `mount_rig.gd`. Não foi executado novo playtest de movimento nesta auditoria.

## Achados prioritários

1. **Quadril parece apoiado na lateral — SW e SE, também perceptível no perfil.** O contato da calça com o dorso não define claramente uma posição a cavalo. Kael parece colado ao flanco, especialmente no screenshot do parque. Medir o eixo dorsal em cada vista e fazer o quadril coincidir com ele. Não resolver deslocando todos os pontos por um mesmo valor.

2. **Oclusão incorreta das pernas — vistas laterais e diagonais.** O cavaleiro inteiro é um único Sprite2D desenhado à frente da criatura, exceto em S. A perna distante deveria passar atrás do corpo, enquanto a próxima e o tronco ficam à frente. A regra atual `seat.z_index=-1 if value=="s" else 1` não consegue expressar isso. Separar perna distante, corpo da montaria, tronco/perna próxima e uma camada frontal do pescoço quando necessária.

3. **Vista frontal com cabeça encaixada entre as orelhas.** O corpo do Kael está atrás da montaria inteira. Só o rosto/cabelo e fragmentos laterais aparecem: a leitura se aproxima de uma figura sobreposta ao pescoço. Ajustar o assento projetado e a oclusão local do pescoço/orelhas, sem pôr o cavaleiro inteiro atrás do animal.

4. **Perspectivas diferentes nas duas folhas.** A montaria é desenhada predominantemente de lado; o Kael sentado revela outra abertura de pernas e altura de câmera. O socket garante uma coordenada comum, não compatibilidade de perspectiva. Fixar uma câmera e desenhar uma pose composta de validação por direção antes de separar as camadas.

5. **Mãos sem apoio claro.** Em W/E e diagonais parecem suspensas diante do colo. Definir onde encostam nas cernelhas; não acrescentar rédeas ou equipamento sem decisão artística. Se a montaria não tiver equipamento, a pose das mãos precisa comunicar apoio leve em vez de segurar um objeto invisível.

6. **Cavaleiro novo muda o acabamento do Kael.** O corpo sentado é uma ilustração reduzida com proporções distintas das folhas em pixel usadas a pé. Na captura do parque, é menos legível e não deve ser considerado substituto final do Kael de gameplay. Validar altura da cabeça, largura de ombros, paleta e agrupamento de pixels junto ao sprite a pé na mesma escala.

## O que pode ser mantido

- Identidade da montaria C, vistas estáticas e conceito de cavaleiro separado.
- Root no chão, câmera fora do assento e Marker2D por direção.
- Manifesto com chão/assento/quadril, extensível a frames de animação.
- Botão de teste e integração do movimento. Isso não aprova as imagens nem uma colisão de montaria final.

## Ordem de correção recomendada

1. Resolver uma única vista SE composta: eixo dorsal, quadril, abertura das coxas, mãos e escala, usando a mesma câmera do mapa.
2. Separar a pose aprovada em camadas próximas/distantes; trocar a regra de uma única ordem Z por direção.
3. Repetir em S, E e N; só depois completar as diagonais restantes. Conferir cada uma no mapa e em miniatura.
4. Fixar o desenho e os pontos; então iniciar o ciclo ComfyUI sem Kael gravado na criatura. O movimento do assento vem da animação da montaria; a oclusão preserva a pose composta aprovada.

Os 588 checks anteriores validaram comportamento e relações de nós. Não medem anatomia, apoio visual, perspectiva ou coerência de estilo. Não usar a passagem desses testes como aprovação do encaixe artístico.
