# Alvo visual v2 — esquina mangá

PIP-82, dentro da PIP-79. **Acabamento de `ESQUINA-ALVO-SIMPLIFICADA.png`
aprovado pelo responsável nesta conversa: “Sim gostei”.**

O aceite abrange a linguagem de desenho deste alvo. A família dos quatro biomas
e a prancha técnica continuam sujeitos à revisão, sem aprovação automática.

A prancha anterior foi rejeitada: aparentava maquete ilustrada. Esta revisão
testa uma única esquina antes de gerar novamente a família dos quatro biomas.

## Direção corrigida

- Desenho 2D de mangá, contorno de tinta expressivo e hierarquia de linhas.
- Formas fortes, cor em massas, sombra chapada e acentos gráficos de rua.
- Energia visual de Splatoon traduzida em linguagem própria: não copiar símbolos,
  personagens, objetos ou interfaces da referência.
- Identidade Soulmonsters: pipas, papel dobrado, varetas, carretéis, nós e rabiolas
  integrados ao cotidiano brasileiro, em objetos com função.
- O cenário preserva superfícies tranquilas para navegação e para leitura da HUD.
- Copas e telhados precisam sobreviver à redução; evitar renderização de folhas
  individuais, milhares de telhas, ruído e sombreado volumétrico.

## Arquivos e limites

`ESQUINA-ALVO.png` é o primeiro estudo, mais detalhado, preservado como histórico.
`ESQUINA-ALVO-SIMPLIFICADA.png` é a revisão de simplificação para avaliação.
`brief.json` registra o prompt inicial e `simplificacao.json` o pedido de revisão.
As imagens são gerações originais via `image_gen.imagegen`, sem imagens de jogos
externos como entrada. A segunda usa somente nosso próprio primeiro estudo.

São alvos de **acabamento**, não mapas integrados ou kits prontos. A geometria da
planta 64 × 32, o relevo de 64 px, colisões e pivôs continuam como contratos técnicos.
Não considerar o pedido de câmera no prompt prova de alinhamento pixel-exato.
O próximo paintover de área precisa nascer da exportação do Mapa Studio e passar
pela tolerância de alinhamento exigida na PIP-79 e suas subtarefas.

Após o aceite desta linguagem: reconstruir a prancha PIP-82, comparar os quatro
biomas com Kael e HUD, aprovar a prancha e só então produzir conceitos e kits.
Nenhuma alteração de mapa, regras, save ou HUD em runtime nesta revisão.
