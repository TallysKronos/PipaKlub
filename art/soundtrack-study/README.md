# Soulmonsters · estudos de trilha V1

Retorno recebido em 28/10/2026: 01 rejeitada; 02 e 03 despertaram interesse parcial, sem aprovação final. Ver `feedback-v1.json` e o curso de composição em `documentation/curso-trilha-soulmonsters.md` na raiz do projeto antes de produzir novas variantes.

Três propostas instrumentais de 56 segundos, geradas no ComfyUI local com ACE-Step 1.5 Turbo e planner Qwen 1.7B. Oito passos de difusão, uma faixa por execução, FLAC estéreo 48 kHz/16-bit. Sem API paga. Prompts completos, parâmetros propostos e seeds estão em `prompts-v1.json`; jobs e medições em `manifest-v1.json`.

| Proposta | Direção pedida | BPM / tom solicitados |
| --- | --- | --- |
| Vila do Primeiro Vento | Acolhimento, começo de jornada, flauta, sintetizador arredondado, violão e piano elétrico | 104 / Ré maior |
| Parque do Morro | Exploração curiosa, marimba, flauta e percussão leve, contraste central de mistério | 112 / Ré maior |
| Duelo de Linhas | Disputa aérea, baixo e bateria mais presentes, motivo ágil de flauta e sintetizador | 148 / Si menor |

Esses são controles solicitados ao modelo, não transcrições musicais verificadas. Compartilhar instrumentação e descrição de motivo pentatônico aproxima a direção; não garante um leitmotiv idêntico entre gerações independentes. O tema comum definitivo deve ser escolhido após a escuta e desenvolvido em arranjo.

## Arquivos

- `originals/`: FLACs gerados, preservados sem alteração.
- `previews/`: MP3s 192 kb/s para escuta, com redução de 4 dB para folga de reprodução. Os originais atingem 0 dBFS; isso não é uma master final para o jogo.
- `workflows/01-vila-v1.json`, `02-parque-v1.json`, `03-batalha-v1.json`: fluxos reproduzíveis, com duração e seed sincronizados também nos nós PrimitiveNode.
- `workflows/ace-step-1.5-local.json`: template original preservado.

O usuário forneceu arquivos identificados pelos metadados como Main Lobby e Central Park de Digimon World 3. Não foram enviados para um serviço, amostrados nem usados em geração de cover; os prompts descrevem uma direção JRPG com melodias novas. Não foi feita análise auditiva dos exemplos ou certificação de originalidade das saídas.

## Preparação e validação

Modelos oficiais: `Comfy-Org/ace_step_1.5_ComfyUI_files` no Hugging Face. Foram instalados `acestep_v1.5_turbo.safetensors`, `qwen_0.6b_ace15.safetensors`, `qwen_1.7b_ace15.safetensors` e `ace_1.5_vae.safetensors`. O VAE também foi disponibilizado na pasta adicional configurada em D:, pois a pasta padrão é uma junction e não foi reconhecida imediatamente. Nenhum reinício do servidor foi executado; a revisão automática recusou essa operação por risco a trabalhos compartilhados. Os três workflows passaram na validação com zero erros, zero avisos e zero nós pagos.

Todos os arquivos foram decodificados integralmente pelo FFmpeg, com duração confirmada em 56 segundos. Não houve revisão perceptiva automatizada, testes de gameplay, integração, commit ou publicação. São propostas para escuta; ainda exigem escolha musical, edição de loop, revisão de artefatos e mixagem no contexto do jogo.

Recriar prévias e metadados com `tools/prepare-soundtrack-study.py`. Não substituir a trilha atual antes da escolha do usuário.
