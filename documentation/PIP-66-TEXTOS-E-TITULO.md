# PIP-66 · Textos e título no Godot

Revalidação de 26/10 na branch `tallysroberto/pip-66-65-textos-icones-glyphs`, em quatro commits específicos dos itens 1–4. Sem merge ou deploy. O pedido anexado autorizou executar todas as suítes e o percurso completo.

## Alterações

- Menu: `Soulmonsters` e subtítulo `Elo das Ruínas`, seguindo a nomenclatura já registrada em `DIRECAO-DE-ARTE.md`.
- Janela e metadados do export: `Soulmonsters: Elo das Ruínas`. Executável previsto: `exports/windows/Soulmonsters.exe`. Nenhum pacote de distribuição foi gerado.
- A pasta de dados continua `PipaKlub`, para manter os saves e as preferências existentes no mesmo local. A empresa nos metadados também não foi renomeada.
- Parque e laboratório de HUD: `Veredas do Encanamento`. Busca textual no diretório `godot/` sem ocorrências da grafia anterior.
- Os cinco pontos de criação de diálogos usam `_dialog(title, text, ok, cancel)`, com títulos e ações explícitos em português. Avisos usam `Aviso`, starter usa `Escolher parceiro` e a saída usa `Sair da bancada`. A demonstração do Theme e o instrumento de clique também receberam botões explícitos em português.
- As pipas decorativas do menu ocupam uma célula própria no cabeçalho de cada cartão. A decoração da pausa ocupa uma linha do conteúdo. `Hud.decorate()` não cria mais sobreposição com coordenada vertical negativa ou z-index elevado.
- `player_visual_audit.gd` compara o retângulo efetivamente visível de cada TextureRect marcado `ui_decorative` com cada Label/Button visível na mesma janela; colisões produzem P1 `decor_overlaps_text`. O teste de HUD injeta uma sobreposição e exige o achado; depois afasta a decoração e exige que o achado desapareça.
- `hud_checks.gd` abre aviso, starter, saída da bancada, conversa do parque e remapeamento e rejeita títulos e botões `Alert!`, `Please Confirm...`, `OK` ou `Cancel`. Passou com 81 verificações.

## Verificação realizada

Suítes de `godot/tests/` executadas e aprovadas, incluindo as novas verificações de ícones e controles. `journey_playthrough.gd -- --with-morro`: 212 verificações, zero falhas. Renderização nativa no Godot 4.7.2, Compatibility/OpenGL, com perfil e armazenamento isolados dentro de `tmp/`.

24 capturas finais conforme o comando solicitado: menu, long-notice, starter, controls, pause e battle nas resoluções efetivas 1280×720, 1280×800, 1920×1080 e 2560×1080. O arquivo final foi analisado após o encerramento da renderização. Menu verifica três decorações por resolução e pausa verifica uma: nenhum `decor_overlaps_text`. Nenhum erro de execução no log final.

O medidor aponta apenas uma linha parcialmente visível na lista rolável de Controles em cada resolução. Esses quatro apontamentos P3 não são sobreposição de decoração nem corte de diálogo; os itens são alcançáveis por foco.

Evidências finais em `documentation/evidence/pip66/revalidation-20261026/`, incluindo logs das suítes, percurso, medições e capturas. Os registros anteriores na pasta de evidências documentam a implementação local precedente; os novos arquivos são a referência desta entrega. Capturas não comprovam controle físico nem funcionamento de um executável exportado.

## Continuidade

O teste de fluxo antigo pressupunha placeholder escuro sobre papel. Como o Theme usa campo escuro, o teste agora mede contraste real com o fundo do próprio campo e exige ao menos 4,5:1. O teste passou. A próxima tarefa na sequência continua sendo a PIP-67, de enquadramento dos cenários.
