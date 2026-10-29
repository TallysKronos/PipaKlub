# Soulmonsters · biblioteca de efeitos V1

**Atualização:** a biblioteca foi conectada à campanha nativa em 28/10/2026. Consulte `documentation/SONS-INTEGRACAO.md` e `integration.json` para o estado atual. As notas abaixo sobre criação e intenção original do pacote foram preservadas; a seção de integração descrevia o estado inicial anterior à conexão.

Pacote para cobrir ações do jogo com uma direção de papel vivo, varetas, linha tensionada, vento e pequenos sinais afinados. São 109 eventos de ação/ambiente com 209 WAVs procedurais, mais seis texturas geradas localmente no ComfyUI: total de 115 entradas e 215 WAVs. Variantes não são contadas como novos eventos.

## Ouvir e localizar

- Abrir `ouvir.html` para pesquisar por evento, categoria e ouvir cada variação. Manter a estrutura de pastas do projeto ou do ZIP.
- `previews/`: montagens de interface, diálogo, progressão, inventário, mundo, oficina, batalha, criaturas, ambientes e texturas. `cues.json` identifica tempos e títulos das montagens procedurais.
- `mapa-de-acoes.md`: ações, funções consumidoras propostas e distinção entre ação existente, futura ou de showcase.
- `godot/assets/audio/sfx-v1/` na raiz do projeto: PCM16 WAV mono, 48 kHz, organizados por categoria.
- `catalog.json`: caminhos `res://`, variantes, bus sugerido, limite de vozes, intervalo mínimo e estado de revisão.

## Cobertura

Interface: foco, confirmação, voltar, abas, opções, mapa, pausa e negação. Diálogos: abertura, avanço, resposta, encerramento e blip opcional. Progressão: salvar, falha de gravação, objetivos, itens, moedas, XP, nível, descoberta e tutorial. Inventário: bolsa, inspecionar, equipar, reparo e restauração.

Exploração: cinco variações de passos em cada uma das quatro superfícies, portas, escada, matinho, baú, rabiola, árvore, copa e fruto. Oficina: seleção, vareta, nó, papel, erro, rajada, equilíbrio, elo, etapa, nascimento e cancelamento. Batalha: encontro, lançamento, rodada, tentativa de ataque, dano de linha/estrutura, crítico, corte, quebra, puxão, esquiva, guarda/bloqueio, energia, especiais, boss, vitória, derrota e fuga.

Chamados sintéticos para Rabbito, Carcará, Azulão, Mata Verde, Raio de Sol e Lacertubo: estudos provisórios de voz, não identidades vocais aprovadas. Proposta para Nozinho sinalizada como legado/proposta, pois o cliente nativo inspecionado habilita a assinatura de Rabbito. Consumo, desequipar e água rasa foram sinalizados como futuros; não inventar mecânicas implementadas.

## Produção

Efeitos curtos: DSP original determinístico em `tools/build-soulmonsters-sfx.py`, com osciladores, ruído filtrado, ressonâncias, envelopes e seeds por evento. Sem samples de outros jogos. Picos de amostra conservadores, camadas e frequências distintas por material. As seis ambiências procedurais usam construção periódica; ainda exigem escuta da junção no contexto final.

Texturas de papel, bambu/madeira, folhas, riacho, cais e caverna: Stable Audio Open 1.0, 30 passos, geração local sem API paga, workflows e prompts preservados. FLACs originais em `ai-originals/`; derivados mono 48 kHz com pico de amostra de -12 dBFS e fades de 20 ms. São gravações geradas, não captações reais. Não estão declaradas como loops perfeitos ou gestos isolados prontos: precisam de seleção/recorte por escuta.

Modelo e identificação de licença do fornecedor: [Comfy-Org/Stable Audio Open 1.0](https://huggingface.co/Comfy-Org/stable-audio-open-1.0). Encoder: [T5-base](https://huggingface.co/ComfyUI-Wiki/t5-base). Pesos não incluídos no pacote. A geração não usou músicas ou sons de Pokémon/Digimon como entrada. O template Stable Audio 3 foi inspecionado, mas não utilizado; a produção usou o template local 1.0 validado.

## Integração: fronteiras e regras

Na entrega inicial, os arquivos eram somente assets mapeados. Na atualização de integração, `sound_director.gd` e `sound_observer.gd` passaram a conectar as ações existentes; front end, preferências, diálogos, metadados de impacto e árvores receberam pontos de áudio. A lógica de save e de dano permanece a mesma. `integration.json` distingue conexões reais de código e assets reservados.

Regras da conexão (a revisão auditiva em partida ainda está pendente):

1. Rotear UI, SFX e Ambience separadamente. Carregar por necessidade, sem abrir todos os WAVs ao iniciar. Manter configurações de volume/mute e opção de desativar blips.
2. Passos dependem de deslocamento confirmado e superfície; não tocar parado contra parede. Variações sem repetição imediata, com pequena variação de altura somente em efeitos não melódicos.
3. Dano vem de `damage_applied`, bloqueio/esquiva confirmada de `combat_feedback`. Não produzir hit ao mero pressionar Espaço. A tentativa de ataque tem evento separado.
4. Recompensa, reparo e salvamento tocam somente após sucesso confirmado. Falha de operação não pode emitir som de sucesso.
5. Oficina: comparar progresso aceito de varetas/nós/papel. Não tocar por frame de mouse; respeitar espaçamento mínimo. Um sinal por etapa ou nascimento, sem repetir ao reabrir o resultado salvo.
6. Guarda dura 0,5 s; seu som não implica invulnerabilidade fora dessa janela. Alertas do boss precisam acompanhar o telegraph real. Aviso de linha baixa tem cooldown de 6 s e nunca substitui HUD.
7. Ambientes param ou fazem transição ao sair da área. Pausa/foco, descarregamento e limite global de vozes devem ser verificados na integração.

## Verificação e reprodução

`technical-review.json` registra existência dos 215 arquivos, leitura integral PCM, formato, não silêncio, duração, pico de amostra e RMS. Isso não é escuta humana, revisão de mixagem com a trilha, medição de true peak da mistura ou teste de gameplay. Não há afirmação de aprovação perceptiva.

Recriar a parte procedural com `tools/build-soulmonsters-sfx.py`, depois os derivados de IA e ZIP com `tools/finalize-soulmonsters-sfx.py`. Ambos usam NumPy/SciPy disponíveis no ambiente Python do ComfyUI e o FFmpeg local do projeto. O segundo requer os seis FLACs originais e os jobs preservados.

Sem testes automatizados do jogo, alteração de campanha, commit, push ou publicação nesta rodada.
