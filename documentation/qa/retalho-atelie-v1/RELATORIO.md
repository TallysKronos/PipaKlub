# Retalho no ateliê — revisão

## Entrega

Cena posterior à vitória no galpão e à conclusão histórica da Vila Operária, conforme a seção 7.4 da Bíblia. Retalho permite a aproximação de Kael, recebe cuidado e Assis reconhece o nó da expedição. O acesso continua válido caso o jogador perca o título do bairro depois.

Três etapas possuem identificadores estáveis e gravação por operação. Interromper conserva somente as etapas confirmadas; retomar abre o próximo trecho. Falha de gravação não avança a história. A conclusão marca a preparação do exame Azul, sem conceder a categoria, capturar Retalho, curar o grupo ou alterar itens, moedas e XP.

Reutiliza o ateliê, os retratos e o sprite aprovado de Retalho. Nenhuma geometria ou passagem foi alterada. O sprite ainda é estático e ereto: uma pose específica de repouso e animação de cuidado continuam pendentes.

## Verificação

- `retalho_care_checks.gd`: 35 verificações headless e 41 em execução gráfica, zero falhas. Inclui pré-requisitos, proximidade, ordem, cancelamento, retomada por save, falha de escrita, repetição e ausência de recompensas indevidas.
- `expedition_photo_checks.gd`: 17 verificações, zero falhas.
- `warehouse_story_checks.gd`: 94 verificações, zero falhas. Os resultados de combate são fixtures; não validam balanceamento.
- Seis capturas nativas revisadas em 1280×720 e 1920×1080: presença no ambiente, três etapas, diálogo ampliado e estado final.

## Limites e pendências

Não foram verificados controle físico, exportação distribuível nem uma partida completa desde o começo. O teste inicia na aproximação segura do ateliê. O exame Azul ainda não foi implementado nesta entrega.

O carregamento preexistente de cinco imagens em `professor_modern.gd` emite aviso de incompatibilidade com exportação. O teste da fotografia também aponta recursos remanescentes no encerramento. Essas ocorrências não foram corrigidas nem consideradas testes limpos de exportação.

A captura de exploração mostra ainda um conflito preexistente entre a parede/quadros e o HUD superior direito. A revisão desta entrega cobre a cena narrativa, não uma aprovação global do HUD.
