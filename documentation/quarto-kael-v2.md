# Quarto de Kael — planta v2

**Histórico superado.** A revisão com a grade reprovou as perspectivas dos PNGs reaproveitados nesta tentativa. Os testes de circulação não comprovam aprovação artística. A versão atual está documentada em `quarto-kael-v4.md`.

## Direção de nível e arte

Referências fornecidas pelo usuário em 23/10/2026: interiores em corte com mobiliário nas bordas, circulação central e saída legível. A implementação mantém a família de cores e os sprites do parque/vila; não copia personagens ou mobiliário das referências.

O quarto foi reduzido de uma área genérica para uma planta de 864 × 640 unidades. A cama ocupa o lado esquerdo, sob a janela. TV e guarda-roupa ficam junto à parede do fundo; a bancada e os desenhos fecham a área de criação à direita. Um tapete delimita a circulação central sem bloqueá-la. A saída é um vão no piso com degraus descendentes e guarda-corpos laterais, conectado ao patamar.

Os PNGs aprovados de cama, TV, guarda-roupa, bancada e baú são reaproveitados sem edição. Piso, tapete, paredes, desenhos e escada são geometria Canvas. A janela é projetada sobre o plano da parede, em vez de ser elevada como um sprite solto. Pivôs específicos aproximam a base visual do canto de apoio de cada móvel.

## Fonte única

`src/bedroom-layout.js` define:

- limites do piso e altura das paredes;
- retângulo de apoio, largura de desenho e pivô de cada móvel;
- vão da escada, bloqueado para caminhada;
- posições da janela e dos desenhos dentro da altura da parede;
- aproximação da TV, desenhos, bancada e patamar;
- entradas e posições da narrativa: mãe, Kael e nascimento de Rabbito.

`bedroomRoom()` fornece a navegação da abertura; `bedroomMap()` gera o mapa Tiled explorável. Ambos partem da mesma planta e usam o mesmo raio de pés. O renderizador usa os mesmos objetos, piso, parede, escala de personagem e câmera nas duas versões do quarto. O mapa PNG legado não é a fonte da física nova.

As etapas de história e as concessões de itens continuam no servidor existente. Não foi alterado o Supabase. Coordenadas de saves que deixaram de ser válidas usam a recuperação existente para uma entrada segura.

## Interação

Os destaques ficam sobre os objetos. Tanto o objeto quanto seu rótulo recebem clique. Cada destino é um ponto de aproximação livre diante do móvel; Kael anda até ele e se orienta para a ação. A escada só fica disponível quando a história libera a saída, evitando pular a montagem.

## Validação

- Suíte completa: 388 testes passaram.
- Testes de planta com amostragem a cada 8 unidades confirmam a mesma aceitação do piso nas duas navegações.
- Centros dos cinco móveis e do vão da escada bloqueados em ambas as versões.
- Destinos da bancada e da escada coincidem exatamente com os nós do mapa explorável.
- Caminhos da mãe, de Kael e do parceiro durante entrada, criação, nascimento e saída permanecem fora dos sólidos.
- Objetos de parede ficam abaixo do topo da parede; áreas de apoio de móveis não se sobrepõem.
- Câmera idêntica entre abertura e exploração em 1280×720, 825×885 e 390×700.
- Rótulos de interação possuem cobertura de clique automatizada.

`npm run audit:world` passou para o projeto modular legado que esse comando examina; a validação específica deste quarto está em `bedroom-layout.test.mjs`, `opening.test.mjs`, `street.test.mjs` e `village-runtime.test.mjs`.

Revisão real no navegador registrada em `documentation/evidence/bedroom-v2/`. A auditoria anterior, em `auditoria-quarto-kael-2026-10-23.md`, permanece como registro dos defeitos da v1.

## Limites

O jogo continua 2D, com sprites e projeção de chão. Não há iluminação 3D ou novos rigs para o mobiliário. A composição foi revisada em janela desktop estreita; telefone físico continua fora desta validação. Esta entrega é local, sem push ou deploy no Render.
