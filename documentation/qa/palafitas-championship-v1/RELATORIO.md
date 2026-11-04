# Palafitas · integração do campeonato

## Implementado localmente

Seyran e Oruvo em A; Kessai e Veldren em B; Caio Garça em C. Eventos aditivos do adaptador de campanha, sem alterar geometria, geradores ou arquivos de mapa. Pontos camináveis com vizinhança livre conferidos: A22,28 /30,16; B18,28 /30,12; C26,12. Sprites usam o contrato revisado de112px e a ordenação existente.

Campeonato liberado após a conclusão histórica da Vila Operária e Mormaço livre. O acesso anterior ao resgate de Retalho continua independente. Quatro vitórias em ordem qualificam para Caio; ele fica oculto antes disso. Níveis24,25,25,26,27, duas rodadas por adversário e três no campeão. Falas curtas de apresentação, vitória e derrota. HUD mostra o próximo adversário e contagem; prioridade antiga de objetivo de Retalho corrigida só quando campeonato disponível.

Progressão e recibo reutilizam district_campaign: derrota/fuga não qualificam, retomada persiste encontro, resultado repetido não reaplica moeda/XP, sétimo emblema uma vez. Defesa e reconquista reutilizam as mesmas regras: perder entrega título ao desafiante e limpa qualificação, mantendo histórico/emblema. Alto da Serra registra desbloqueio no catálogo, mas segue sem viagem por ainda não estar integrado.

## Verificação

| Verificação | Resultado |
| --- | --- |
| Palafitas campeonato, serviço/save/recibos |97 checks,0 falhas |
| Fluxo nativo, eventos, confirmação e tela de batalha |43 checks,0 falhas; seis capturas1280×720 |
| Caminhada A/B/C, agora incluindo eventos de campanha |433 checks,0 falhas |
| Regras genéricas dos12 bairros |452 checks,0 falhas |
| Definição Vila Operária |62 checks,0 falhas |
| Campanha Vila Operária |60 checks,0 falhas |
| Mormaço |44 checks,0 falhas |
| Arco de confiança Retalho |97 checks,0 falhas |
| Mapa Studio model.test.mjs |6 testes,0 falhas |

Testes usam saves isolados, sem conta real. Na suíte de Palafitas os resultados terminais foram fixtures: validação de combate/fluxo e liquidação, não uma vitória jogada do início ao fim por humano. Confirmação disparada pelo sinal real da interface, não teste de botão físico/controle. Capturas de cada ponto inspecionadas. Testes não provam balanceamento.

## Pendências explícitas

O crocodiliano aprovado ainda NÃO é a espécie usada na batalha de Caio. Os cinco encontros usam os quatro modelos e a arena já suportados pelo combate de bairros; Caio aparece com Mata verde provisório, documentado em caio-battle-provisional-art.png. Não registrar esse modelo como parceiro canônico. Falta pacote de batalha próprio do crocodiliano (nome, dados e arte), cenário de combate das docas, retratos de diálogo e caminhada/rig Soulgen dos NPCs. Artes estáticas continuam mais suaves que o Kael pixelado atual.

Não foi alterada a geometria; não houve nova auditoria de todos os cantos/rampas em versão geométrica. Percurso programado e capturas dos pontos são as evidências desta entrega. Avisos do ambiente: cache de shader/user:// e recursos já presentes no teste Mormaço; o teste Retalho também reporta avisos de carregamento do cômodo. Sem falha nas respectivas contagens.

Sem merge, push ou deploy. Fontes e kit.json alheios preservados; arquivos de save de teste não entram no commit.
