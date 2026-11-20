# Alvacordo — idle e caminhada 64×64

Dois ciclos produzidos no Aseprite a partir da pose-mestra com lineart interna v5, sem regenerar o rosto ou os detalhes entre frames. Primeiro frame do idle idêntico pixel por pixel à pose original.

- Canvas 64×64, uma direção sudoeste, paleta de 12 cores e alpha binário.
- `idle-so`: frames 1–8, 1.440 ms. Respiração de 1 px com atraso da cabeça/braços, pés fixos e pequeno movimento da rabiola.
- `walk-so`: frames 9–16, 920 ms. Contato, apoio, passagem e subida por perna, deslocamento oposto dos braços com os arcos e rabiola secundária.
- Rig: cauda, duas pernas, juntas sobrepostas, torso, dois braços com arcos e cabeça. Não são pivôs arbitrários no runtime; são cels em posições inteiras para animação pixel.

Fonte editável: `alvacordo-64.aseprite`. Atlas: `alvacordo-64.png` / `.json`. Prévia: `idle-6x.gif` e `walk-6x.gif`, ampliação nearest-neighbor. `walk-strip-3x.png` é diagnóstico dos oito frames da caminhada. `PixelSpec.json` registra o rig e as chaves. `validacao.json` mede os exports.

A primeira revisão detectou a raiz da cauda desconectada nos quadros globais 5–7 e 10–11. Corrigido apenas o encaixe sob os acessórios nesses cinco quadros, em x46–51/y39–42. O snapshot `antes-correcao-raiz.aseprite` preserva o estado anterior. Após a correção, cada um dos 16 quadros possui um único componente de alpha em oito vizinhos; a inspeção visual complementa essa medida.

Sem integração no jogo nem calibração de movimento em pixels/segundo contra a velocidade do personagem. Somente uma direção, sem corrida ou demais ângulos. Avaliação visual do autor pendente.
