# Novo elenco do Parque
Substituições locais: Bia → Iara (Jardim); Juninho → Nilo e Lia → Dora (Clareira); Zeca → Cauê e Tião → Celina (Veredas).
Os personagens originais continuam disponíveis nas áreas às quais pertencem.

## Entrega
- Cinco sprites direcionais nativos 64×96, atlas 256×192, oito vistas estáticas S/SO/O/NO/N/NE/E/SE.
- PNGs exportados pelo Aseprite; fontes .aseprite editáveis no pacote e documentos .pixelgen.json ligados ao álbum e ao PNG consumido pelo jogo.
- Retratos e falas próprios. Escala relativa ao Kael, preservando diferenças de altura.
- Dora afastada do poste da clareira após conferência nativa.

## Compatibilidade
IDs internos dos duelos e recibos park-trainer-* preservados. Nenhuma migração ou reinicialização de progresso. Mesmos adversários, níveis, recompensas e progressão até nível 8.
O atlas .aseprite guarda as oito vistas em uma única tela; o documento Pixelgen guarda uma vista por quadro. Não são ciclos de caminhada.

## Validação
- 91 verificações de jornada e batalhas, zero falhas.
- 36 verificações na interface Godot, cinco NPCs e dez capturas 1280×720 com salvamento isolado.
- Seis testes do álbum e persistência do editor, zero falhas.
- Quarenta vistas com transparência binária, até 32 entradas de paleta e equivalência exata entre exportação nativa e Pixelgen.
- Crítica visual independente: Iara/Nilo/Dora/Celina 8/10, Cauê 7,5/10, nenhum bloqueante.
- A ferramenta validate do MCP não está exposta nesta sessão; verificações mecânicas realizadas pelo script review-park-pipeiros.py.

## Proveniência
Arte gerada com referências individuais aprovadas em art/characters/parque-pipeiros-v3, normalizada por escala uniforme por identidade, paleta compartilhada entre vistas, limpeza de pixels desconectados e contorno. Grades aplicadas e exportadas no Aseprite MCP em modo headless.
Fontes e prompts literais retidos em art/characters/parque-pipeiros-runtime-v1/fontes. Não foi feita animação nova nem geração por vídeo nesta entrega.
