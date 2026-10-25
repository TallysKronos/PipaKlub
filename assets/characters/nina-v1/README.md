# Nina — primeira missão das Veredas

Nova aprendiz de construção de pipas. Pele morena, cabelo cacheado preso, faixa verde-petróleo, camisa amarela, bolsa de papel e varetas. O Carcará dela perdeu o duelo contra Lacertubo; sua rabiola ficou no pátio.

## Arte e contratos

- Gerados com a ferramenta integrada image_gen em 25/10/2026; referência de acabamento: `assets/ui/dialogue-v1/kael.png`.
- `portrait.png`: 1024×1536 RGBA, retrato próprio para diálogo. Registrado no manifesto de diálogos.
- `overworld.png`: 1024×1536 RGBA, corpo inteiro em pose parada. Altura de referência: 1441; apoio dos pés: (530,1480). O manifesto repete a pose nos oito slots existentes para compatibilidade; não representa uma animação de caminhada.
- Alpha verificado: mínimo 0 e máximo 254 nos dois PNGs. Não houve recorte ou pintura posterior. As imagens foram copiadas para este diretório e são empacotadas pelo build.
- Fontes preservadas em `.codex/generated_images/.../exec-561ebad9-d5c5-4dae-8dc9-b3d4cc6a57f4.png` e `exec-01b3a51b-341d-4d54-aee4-b16f4b9dbd09.png` no computador de produção. Sem dependência desses caminhos em runtime.
- A rabiola no chão reutiliza `items/rabiolas/rabiola-carcara.png`; brilho e faísca são desenhados no Canvas, respeitando movimento reduzido.

## Missão

Voz na entrada → pistas opcionais → apresentação de Nina → aceitar o pedido → vencer Lacertubo → recolher a rabiola brilhante → devolver → reencontrar Nina com Carcará.

Há três percursos conectados até o pátio. As pistas não são chaves obrigatórias. O início da batalha continua sendo uma escolha explícita.

A vitória vem do estado confirmado pelo servidor. Aceitação, coleta e entrega desta missão narrativa são gravadas localmente por conta em `pipaVeredasStoryV1`; ainda não são sincronizadas entre dispositivos. Reiniciar a campanha limpa essa memória. O objeto de missão não concede uma cópia de Carcará, moeda, XP ou rabiola utilizável ao jogador.

Verificações: caminhos de ida/volta, seguidor, encadeamento do diálogo, adiamento/aceitação, impossibilidade de coletar antes da vitória, entrega e não duplicação. A revisão visual usa cenários isolados do jogo, sem alterar contas reais.
