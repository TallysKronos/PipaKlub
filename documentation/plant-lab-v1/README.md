# Bancada top-down — 05/11/2026

Ferramenta em `tools/plant-lab/`, aberta em **http://127.0.0.1:5256**. Exporta um projeto Godot independente com o layout atual. Cópia inicial nativa: `tools/plant-lab/godot-preview/project.godot`.

## Verificado

Cinco testes automatizados de modelo/servidor/exportação passaram. No Chromium real foram exercitados13fluxos: plantar; mover; espelhar; duplicar; excluir; desfazer/refazer; pintar piso continuamente; desfazer a pincelada inteira; exportar Godot com a alteração atual; recarregar mantendo composição; importar JSON válido/inválido; mover Kael em teste; ligar/desligar grade.

Capturas em1440×900,1280×720,1920×1080 e844×390. O teste verificou ausência de overflow horizontal da página, canvas utilizável e ausência de erros JavaScript. A área do mundo pode ser maior que o canvas em janelas pequenas; o pan permite percorrê-la. A inspeção visual foi feita nas capturas1440×900 e844×390; as outras também foram registradas pelo teste.

Godot4.7.2 importou e executou a cópia inicial em headless sem erros de script. Esse teste não valida a experiência manual da janela nativa. O piso nativo é uma base procedural mais simples que a prévia web; disposição, escala e ordenação por raiz compartilham o mesmo layout.

## Limites

Pisos de apoio, poses estáticas e sem colisões. Não houve integração com cenas ou saves da campanha, geração de terreno final, commit ou push. Nenhum asset anterior foi substituído.

`captures/jardim-editado-godot.zip` é a exportação real produzida pelo teste, contendo uma composição com a peça movida e espelhada. `captures/verificacao.json` lista os fluxos e viewports.
