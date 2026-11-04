# Montarias 2D — primeira integração

01/11/2026. Doberman C, conceito ainda sem nome canônico. Versão estática jogável; nenhuma animação de caminhada/corrida foi criada nesta etapa.

## Decisão: encaixe, não personagem achatado junto da montaria

O Godot documenta [Marker2D](https://docs.godotengine.org/en/stable/classes/class_marker2d.html) como ponto de referência 2D e [Node2D](https://docs.godotengine.org/en/stable/classes/class_node2d.html) como transformador dos seus filhos. Aplicação ao projeto: um grupo acompanha o chão; um Marker2D representa o assento; o sprite sentado do Kael é filho desse marcador. Não girar uma imagem plana para simular outra direção.

```
Raiz do jogador — posição, colisão, altura e ordenação atuais do mapa
└─ Avatar
   └─ MountRig — manifesto selecionável
      ├─ MountBody — imagem da criatura por direção
      └─ RiderSocket (Marker2D) — ponto do assento
         └─ Rider — pose sentada do Kael por direção
```

Manifesto: `godot/assets/mounts/doberman-c-v1/mount.json`. Para cada direção registra `rect`, `ground`, `seat`, `riderRect`, `hip` e uma reserva de metadados `frames`. `ground` é o apoio no chão; `seat` é a posição do assento na imagem; `hip` é o ponto de encaixe do quadril na pose sentada. A diferença desses pontos fornece o deslocamento. Cada criatura futura escolhe outro manifesto em `mount_definition_path`; o cavaleiro pode continuar usando suas próprias poses. Não há dependência do desenho de uma criatura no código de movimento.

A ordenação interna usa duas máscaras complementares do cavaleiro: perna distante atrás da criatura e tronco/perna próxima à frente. O manifesto define `farLeg` como polígono no espaço do recorte do Kael. As máscaras não recortam o casaco em uma divisão horizontal. A vista frontal adiciona `neck`, um recorte do pescoço/cabeça que pode passar à frente de parte do cavaleiro sem escondê-lo inteiro. A câmera e a posição salva continuam ancoradas no chão, nunca no assento. Materiais de oclusão do mapa são herdados pela criatura e copiados para o shader das camadas do cavaleiro na cidade. Na floresta, a altura de leitura para oclusão considera a montaria. A recuperação do parceiro em uma curva travada usa caminhos válidos do mesmo mapa, sem teleporte.

## Uso e limites desta versão

- Botão Montar/Desmontar na HUD, tecla B ou direcional para cima no controle, durante exploração. Rejeita alternância em pausa, carregamentos, escadas e ações incompatíveis. O botão usa o mesmo controlador.
- Vila, parque/mapas regionais e Morro compartilham o avatar. A montaria acrescenta 35% à velocidade de deslocamento. O parceiro continua seguindo.
- Montar não muda a posição, altura, missão, XP, inventário ou checkpoint. Nenhum nome, elemento, obtenção, preço ou desbloqueio foi inventado.
- O estado montado é temporário da cena. Entrar em batalha/interior ou trocar de mapa recria o avatar a pé. Persistência/equipamento de montaria é uma etapa futura.
- Escadas encenadas, saltos e pose de recebimento de item retornam ao Kael normal. Não criar animação falsa de escalada com a montaria estática.
- A sustentação usa o controlador atual do jogador. Ainda não há footprint largo específico da criatura nem bloqueio por tamanho em passagens estreitas. O desenho pode ocupar mais espaço que esse controlador: revisar antes de tratar como funcionalidade final.
- Arte em manga 2D transparente; não declarar os recortes como pixel art artesanal. O cavaleiro sentado é um estudo novo e mantém a identidade do Kael. A folha tem oito poses estáticas, não oito frames de caminhada.

## Etapa seguinte — ComfyUI

1. Produzir idle, caminhada e corrida da montaria SEM o Kael na imagem, com câmera travada por direção, escala e apoio constantes. Começar por uma direção e um ciclo curto aprovado.
2. Extrair frames e medir o pivô do chão de cada um. Evitar alinhar pelo retângulo total: o movimento das orelhas e rabiolas altera esse retângulo.
3. Anotar `seat` por frame, além de duração e retângulo. Usar esse movimento para o RiderSocket. Não aplicar bob arbitrário por tempo independente do ciclo.
4. Atualizar as máscaras `farLeg` e a camada `neck` quando o movimento mudar as sobreposições. A versão estática já tem essas camadas; uma animação não deve manter máscaras fixas se as pernas mudarem de posição.
5. Usar as poses sentadas do Kael como base e só então animar tronco, mãos e pernas, sincronizados ao mesmo relógio da montaria. Não gerar um vídeo composto que grave permanentemente o Kael dentro do animal.
6. Validar loop, patas, mudança de direção, aceleração, parada, rampas, oclusão e contato assento/quadril em captura nativa. Só depois repetir o contrato para novas montarias.

Skeleton2D/IK não são necessários para a primeira integração de sprites desenhados. Podem ajudar futuramente em mãos/pés separados, mas não substituem as vistas e os pontos de encaixe. Não foram introduzidos nesta etapa.
