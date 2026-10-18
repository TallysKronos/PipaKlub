# Quintal modular — verificação da reconstrução

- Oito peças novas em duas folhas RGBA originais, geradas com image_gen; 34 peças disponíveis contando o kit compartilhado. Prompts e recortes medidos preservados nesta pasta.
- Planta final: 1536×1024, seis camadas Tiled, 98 objetos, 10 decorações explícitas. Telhado, copas e portão são partes de frente separadas das bases; composição final contém 91 sprites.
- Seis ações anteriores preservadas, sem novos encontros, recompensas ou operações de conta.
- O quintal padrão do build vem da planta e do kit; não depende da pintura panorâmica antiga. O Ateliê abre exatamente os mesmos dados em `/?project=quintal`, com gravação automática separada do Morro.
- Gramado e caminhos caminháveis, bases sólidas de prédios/mesa/banco/postes/árvores, pilares e folhas do portão com colisões próprias, vão central livre. Professor, Nozinho e ponto inicial do parceiro em áreas seguras.
- Busca de caminhos passou a usar fila de prioridade e adjacências pré-calculadas. Medição inicial no mesmo processo local: seis rotas de 293 ms para 6 ms; não é garantia de desempenho para outros dispositivos.
- Build servidor, Pages e validação ESM aprovados. Suite de 236 testes: 235 passaram no sandbox; WebSocket bloqueado por EACCES passou com rede local liberada. Após ajustes finais de câmera, parceiro e folhas do portão, os 34 testes de mapa/navegação/atores/editor passaram novamente.
- Inspeção no navegador: chegada ao quintal modular, caminhada até Sr. Assis com interação disponível, Kael e parceiro separados na chegada, sem erros de console na demonstração.
- Demonstração em `127.0.0.1:5208`, banco isolado `.local/quintal-modular-check`; não acessa Supabase real. Bancada anterior preservada.

Sem commit, push ou deploy nesta etapa. Assets e código aplicados localmente. Próximas edições feitas no Ateliê precisam de exportação, revisão e build para aparecerem no jogo.
