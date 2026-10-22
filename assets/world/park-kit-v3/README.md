# Parque das Pipas — continuidade visual v3

Revisão de 21/10/2026. A composição usa tiles e objetos editáveis; não substitui o mapa por uma ilustração única.

## O que mudou

- Materiais de gramado, terra, pedra e capim gerados na mesma prancha. O renderer mantém a proporção das amostras e usa repetição refletida para unir as bordas, sem interpolação que traga cores da próxima região do atlas.
- Capim mantém o sentido vertical das folhas; os três habitats são uniões de retângulos sobrepostos, recortadas uma vez. Não são dezenas de cópias do mesmo tufo.
- Caminhos mais largos, curvas contínuas e transição de 5 unidades de mapa entre materiais. A máscara é feita uma vez no cache do chão; não custa uma recomposição por passo.
- Removida a borda de pedrinhas que contornava o retângulo inteiro da área caminhável, incluindo o gramado.
- Dois modelos novos de árvore sem pipa, calibrados pela altura visual. Árvores com pipa ficam como marcos pontuais; flores e bancos pertencem aos recantos de descanso.
- Árvores completas conservam colisão somente no tronco e atenuam a copa ao encobrir o personagem no mesmo piso.

## Fontes

`terrain-v3.png` e `nature-v3.png` foram produzidos com image_gen integrada usando as folhas v2 e a composição conceitual como referência. Originais preservados, sem repintura ou reamostragem. Prompts integrais em `prompts.json`; medidas e hashes em `validation.json`.

O coreto, a árvore florida e o marco da árvore com pipa continuam vindos de `park-kit-v2/park-atlas-v2.png`. Recortes no manifesto v3. Bancos, postes e dois vasos usam o kit do jogo, na mesma escala e paleta do descanso.

## Regras de montagem e auditoria

1. Repetir material sobre a coordenada global do mapa. Nunca reiniciar a textura em cada retângulo de piso.
2. Preservar proporção da textura e desativar suavização no recorte para evitar mistura com a amostra vizinha.
3. Unir a geometria de cada material antes de recortar. Junções internas não recebem borda, sombra ou linha.
4. Manter folhas de capim orientadas para cima; não inverter sua textura verticalmente.
5. Habitat visual precisa corresponder à união das áreas de encontro. Gramado baixo e caminhos não viram encontros.
6. Não repetir uma pipa, vaso, cerca ou tufo como enchimento aleatório. Distribuir vegetação em grupos e preservar acessos.
7. Árvore inteira, tronco apoiado, escala visual consistente entre variantes, colisão de base e oclusão testada com personagem.
8. Comparar mapa inteiro e escala do personagem. Testar descanso, placa, ambas as saídas e centro de cada região de habitat.

Mapa: `assets/world/park-v1/*.tmj`; composição: arquivos `.art.json`. Fonte editável e gerador: `scripts/build-park-content.mjs`. Não executar o gerador sobre edições manuais sem revisar o diff.

## Verificação

Prévia: `node scripts/preview-park.mjs`, http://127.0.0.1:5233/. Usa os mesmos módulos de terreno, ordenação, objetos e navegação do jogo, com comparação antes/depois e caminhada do sprite de Kael. Não acessa contas ou banco. O JSON anterior é uma captura de revisão.

Testes em `park-coherence.test.mjs` verificam acesso, materiais, habitats, continuidade das bordas refletidas e oclusão de árvores. A suíte completa passou com 327 testes; builds Worker e Pages e validação do artefato concluídos. Logs em `tmp/park-coherence-full-tests.log`.

Integração local; sem deploy ou aplicação de migrações em produção neste trabalho. A inspeção de layouts não equivale a um novo teste completo de campanha ou multiplayer.
