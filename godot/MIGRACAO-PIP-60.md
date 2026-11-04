# PIP-60 — migração Godot / Steam

Atualizado em 25/10/2026. Tarefa: https://linear.app/pipaklub/issue/PIP-60/migrar-pipaklub-para-steam-com-campanha-offline-e-online-opcional

## Decisões

O responsável escolheu Godot para Steam e outras plataformas. A recomendação histórica Electron não é o plano atual. Cliente JS e migrações SQL continuam como referência. Campanha offline; online opcional. Sem Steamworks/App ID por enquanto. Sem credenciais, publicação ou alterações de banco nesta entrega.

## Implementação local

Menu/slots, prólogo, professor, treino e oficina conectados. Rua, Jardim das Pipas, Clareira do Papel e Veredas estão conectados. Dois mapas iniciais exportados em camadas do renderizador original com geometria canônica. Missão da Nina, cinco baús, Lacertubo com duas fases, batalha persistente, desaparecimento do boss, rabiola própria e de missão separadas, devolução, encontros no mato, drops, coleção, bolsa, bancada para rabiolas encontradas e reparos. Filtro CRT opcional, ativo por padrão. Executável Windows exportável via `Exportar.ps1`, com licenças e hashes.

Saves com schema/conteúdo/regras v1, UUIDs e recibos, escrita temporária verificada e backup. Falhas não publicam estado em memória. Recuperação preserva backup e arquiva primário danificado. Versões futuras não são sobrescritas. Não há migração automática de saves web/protótipo, lock entre processos ou certificação online.

## Evidências

Autorização humana explícita para verificações isoladas. 141 verificações de domínio/persistência e 17 de integração aprovadas. Pastas únicas, sem tocar nos saves reais. Inclui falhas de save, backup, futuro, repetição, missão, combate retomado, estoque, cancelamento e oficina. Comparações derivadas do JS original: três oficinas completas, movimento dos quatro tipos e duas fases do boss por 12 segundos. Resultado sintético é usado só para testar transações/transições, não como vitória de playtest. Revisão visual em 1280×720.

## Pendências para fechar a tarefa

- Playthrough completo do novo jogo ao boss, validação com rede desativada, equivalência completa do tutorial e combate, dificuldade e medições de inicialização/desempenho.
- Áudio, controle completo da bancada, remapeamento de gamepad, especializações e outras manobras. Morro do Sol e parque estão conectados à campanha.
- Polimento da UI nativa para paridade integral com o kit original, créditos/licenças no menu e ícone final do aplicativo.
- Cadastro Steamworks/App ID, integração da plataforma, serviços online opcionais e política de certificação dos parceiros. Nenhum parceiro local é declarado certificado.

Não marcar PIP-60 como concluída com base em exportar ou inicializar o menu. Ver `README.md` para comandos e limites. Assets Soulgen pausados; próximo: Platofolha.

Atualização do percurso: 188 verificações de domínio, 23 de integração e 1510 de geometria aprovadas. Inclui níveis dos encontros iniciais e retorno à área correta após fugir. Objetos ambientais dos mapas iniciais estão na pose exportada, sem animação nativa. Teclado nessas áreas; clique permanece nas Veredas. Capturas 1280×720 revisadas. Build Windows reconstruída sem erros.

Controles: 12 ações do teclado remapeáveis com detecção de conflito e persistência; controle integrado à exploração/treino/batalha, analógico com zona morta, dicas dinâmicas e desconexão. 19 verificações de entrada simulada aprovadas; sem teste físico. Bancada ainda exige mouse; remapeamento de controle e glifos por modelo pendentes. Export Windows reconstruído sem erros.

Percurso contínuo roteirizado aprovado em 25/10: 105 verificações, sem concessões artificiais, da abertura à devolução da rabiola e reparo. Novo processo retomou o save real dessa jornada isolada (7 verificações). Corrigido bloqueio da validação JSON na etapa de vento da oficina. Regressão: 206 regras/persistência, 23 integração e 19 entrada aprovadas. Export Windows atualizado; inicialização headless do executável com saída 0. Continua pendente playtest humano, rede fisicamente desativada e paridade das rotas restantes. Ver PLAYTEST-2026-10-25.md.

### Morro do Sol — integrado e jogável em 25/10

O módulo `scripts/campaign/morro_rules.gd` preserva os cinco desafios, estrelas,
moedas, bônus da primeira vitória, rabiola única de Mikka e dificuldade adaptativa.
Os diálogos e parâmetros são exportados diretamente de `src/trails.js` com
`node scripts/godot-morro-sync.mjs`; o desfecho utiliza a variante da demo.

Validação isolada: `tests/morro_checks.gd` passou em 377 verificações, incluindo
367 comparações com resultados do JavaScript original, derrotas consecutivas,
limites de maestria, vitórias repetidas e desbloqueio sequencial.

Os cinco mapas agora estão disponíveis pela Rua dos Ventos. Movimentação por
teclado/analógico e clique respeita as colisões e as conexões de altura originais.
Juninho e Lia disputam simultaneamente e também se atacam. Séries de 2/3 vitórias,
intervalos, placar, diálogos, revanche, saída para a cidade, portões persistentes,
XP, moedas e rabiola de Mikka estão integrados aos saves locais. A rabiola original
`rabiola-raio-de-sol` usa o alias de receita nativa `rabiola-raio`.

O percurso desde Novo jogo, passando pelo Morro, boss e missão de Nina, terminou
com 198 verificações aprovadas. Inclui retomada exata da disputa com três atores.
São entradas roteirizadas, não playtest humano de descoberta ou equilíbrio.
Transações sintéticas separadas: 47 verificações; regras: 377. Medição gráfica
local próxima de 60 FPS em 1280×720/RTX 3060. Detalhes em
MORRO-PLAYTEST-2026-10-25.md. Não concluir PIP-60: Steam, áudio e os demais itens
pendentes continuam fora desta entrega.
