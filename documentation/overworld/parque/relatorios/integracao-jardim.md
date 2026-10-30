# Jardim das Pipas — atualização na campanha

Atualização trazida de `origin/codex/mapa-jardim-das-pipas` (`160b673a`): os três commits novos `cdf1edc8`, `af5f068d` e `160b673a` foram aplicados sobre `codex/integracao-bosque-kronasta`, preservando os serviços e a integração local do Bosque. Não houve merge em main ou push.

O novo Jardim substitui a planta anterior com praça elevada, coreto, pomar, mirante e rampas. A Clareira da campanha conserva sua geometria; recebe somente os metadados de chegada de retorno ao Jardim. Os executáveis locais do motor não fazem parte dos commits.

## Compatibilidade resolvida

- Conflitos do renderer foram combinados para manter materiais manga, água, chegadas nomeadas, banco e marcadores persistentes da campanha.
- Nina continua disponível perto da entrada para iniciar e concluir a missão existente. A campanha acrescenta o evento `8243`; o ID `43` da nova planta é uma entrada. O roteiro e a cutscene futura citados na entrega do construtor não foram inventados nesta atualização.
- O treino de Assis usa a posição real do guia no novo Jardim, preservando o recibo e a recompensa existentes. Os demais treinadores conservam suas identidades.
- Os quatro materiais do Jardim usam o mesmo serviço de recibos atômicos do Bosque. O recibo usa o ID do mapa para que a coleta esconda o marcador e não conceda uma segunda recompensa.
- O retorno da Clareira respeita a chegada norte `36,2` do Jardim. A chegada `3,13` da prévia do construtor não é suportada pela Clareira maior desta branch; nesse caso permanece sua entrada sul válida.
- A receita de capim utiliza os arquivos/shader já existentes quando o kit atual não contém o campo antigo `encounterGrass`.
- A máscara de terreno da Clareira foi preservada. Antes de atualizar o hash do manifesto, foram comparados todos os dados exceto eventos com o commit anterior; a alteração é apenas dos metadados de saída.

## Validação local

- Node: 10 testes do Jardim e conferência do Bosque passaram.
- Travessia do Jardim: 49 alvos, 98 viagens, 30.300 frames, zero falhas; inclui entrada e retorno da Clareira.
- Campanha real com capturas nativas: 104 verificações, zero falhas; inclui início e conclusão da missão da Nina, coleta persistente, combate com Lacertubo, retorno, fuga e recarga em disco. Evidências atualizadas em `documentation/overworld/park-campaign-v1/`.
- Regressão do Bosque: 114 verificações headless, zero falhas, 12 recompensas. As capturas nativas da integração anterior permanecem em sua pasta.
- Overworld: 97.687 verificações, zero falhas.
- Ritmo de encontros: 675 verificações, zero falhas.

Todos os saves de teste são temporários e isolados. A execução gráfica nesta máquina informa falta de acesso ao cache de shaders em `user://`; a suíte headless ampla mantém o diagnóstico de shader de outro bioma já documentado. Asserções e capturas funcionaram; não se declara ausência de mensagens do motor nem playtest humano.

Para testar no Godot, abrir `godot/project.godot` nesta worktree e executar o projeto completo com F5. O Jardim está no acesso normal do parque; o Bosque continua em M → Região de Kronasta.
