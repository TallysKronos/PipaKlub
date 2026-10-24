# Além da cidade: Veredas do Encanamento

Implementação local de 24/10/2026. A segunda rota da demo atravessa Jardim das
Pipas → Clareira do Papel → Veredas do Encanamento. A saída nordeste da Clareira
abre o terceiro mapa; a saída sul das Veredas permite retornar.

## Level design

Mapa isométrico 1536×1024, na projeção e escala atuais. Três cercas vivas longas
alternam a passagem entre leste e oeste, com dois desvios sem saída. Corredores
de pelo menos 112 unidades, entrada ao sul e pátio do boss no nordeste.
Colisões, caminhos e desenho dos arbustos partem dos mesmos retângulos em
`src/park-boss-layout.js`. Os canos são cenário sem novas barreiras invisíveis.
Não há sorteio de encontro no labirinto: o boss exige interação no pátio.

## Lacertubo

Nome provisório. Lagarto de papel facetado com remendos, armação e juntas de PVC,
amarrações laranja, vela dorsal e rabiola de bandeirolas. Olhos pequenos e
contornos escuros seguem o Carcará. Arte raster gerada com image_gen; recortes,
pivôs, hierarquia e animações foram montados no sampler real do Soulgen.

Oito peças articuladas (incluindo patas distantes), seis ações, 127 quadros a
12 fps em células 256×256. Idle, voo, golpe, dor, vitória e entrada. Rugido e
dor têm cabeças substitutas. Arquivo editável:
`art/soulgen/keys/lacertubo/color-rig-v2/lacertubo.soulgen.json`.
Editor local: `http://127.0.0.1:5258/?preset=lacertubo`.
Reexportação: `node scripts/build-lacertubo.mjs`.

## Combate e ajuste inicial

Nível recomendado **do parceiro**: 15. Isso não é um bloqueio de acesso nem usa
o nível da conta. São parâmetros iniciais, sem partida de balanceamento executada:

| Parâmetro | Valor |
|---|---|
| Integridade | 190 |
| Energia / regeneração | 125 / 19 por segundo |
| Ataque / defesa | 1,18 / 1,05 |
| Velocidade | 157 |
| Fase 2 | Abaixo de 55% da integridade, sem cura |
| Preparação do golpe | 1,15 s → 0,8 s na fase 2 |
| Recuperação / vulnerabilidade | 1,5 s → 1,15 s; recebe 20% mais dano |
| Intensificação da fase 2 | Dano ×1,12; IA 6 → 7 |
| Limite | 120 s; precisa derrotar o boss, não apenas sobreviver |

A mira trava nos últimos 40% da preparação. O jogador pode escapar do
cruzamento, esquivar e contra-atacar. Os golpes continuam exigindo contato
válido na engine. A HUD mostra integridade, fase e estado da armação, sem
exibir a lista de ataques inimigos. Entrada de 3,4 s seguida da preparação;
movimento reduzido preserva texto e sinais de combate.

## Progresso e persistência

Reutiliza a reserva privada, retomada, fuga, pausa e fila de confirmação dos
encontros selvagens. A conta não perde o parceiro. Derrota retorna à entrada
das Veredas; vitória retorna à posição anterior. O resultado do boss é
separado de drops aleatórios; não concede um parceiro ou rabiola do boss.
Primeira vitória: até 120 XP do parceiro; repetição: até 60 XP, sujeitos ao
limite do parceiro. Tamer segue a regra existente de XP realmente concedido.
A conclusão das duas rotas depende de resultados confirmados no servidor.

`028_park_guardian.sql` adiciona a área, checkpoints e recibo de vitória;
preserva dados atuais e mantém RPCs de resultado restritas ao servidor.
Aplicada somente no banco local ao iniciar o ambiente de revisão. Não aplicada
em produção e sem deploy nesta entrega.

## Verificação efetivamente realizada

- Exportação pelo sampler e validação estrutural do projeto Soulgen.
- Inspeção das imagens e da prancha montada; fontes com alpha e recortes nativos.
- Builds Worker e Pages; o parser de mapas valida conectividade dos pontos.
- Inicialização do servidor local com migração 028, preservando a base anterior.

Sem testes automatizados, walkthrough ou auditoria de gameplay nesta demanda,
respeitando a orientação do usuário. Ainda precisam de partida real: dificuldade
no nível 15, legibilidade dos avisos e enquadramento responsivo da HUD.
