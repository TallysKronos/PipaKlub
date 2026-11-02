# PIP-136 — Resultado e grandes momentos

Implementada a apresentação Mural compartilhada entre encontros, Lacertubo e Morro do Sol. Vitória, derrota e recuo têm peças próprias, com extremidades ilustradas fixas. O recibo apresenta pipeiro, parceiro ativo, reservas sem participação, XP, estrelas, moedas, passagem e itens calculados pelas regras existentes. Não há alteração no balanceamento.

## Ordem verdadeira das recompensas

O fluxo anterior só liquidava a batalha ao continuar. A interface agora reconhece isso: o recibo é uma **prévia estática**, marcada como tal. Não anima XP previsto como se já tivesse sido concedido. Falha ao salvar oculta as recompensas, retém a batalha e oferece tentar novamente. Não dispara o wipe de vitória nessa condição.

Depois do sucesso das operações existentes save_battle/settle, o frontend compara os níveis antigos com o snapshot efetivamente gravado. Se houve subida, mostra uma chamada de 1,7 s e volta ao mundo salvo; a confirmação repetida fica bloqueada durante essa apresentação. As operações de concessão e seus identificadores não foram duplicados ou substituídos.

A chamada de nível é cosmética: se o aplicativo for encerrado nesse momento, o ganho já está salvo; ela não cria uma nova pendência de save. Entregas de documentos e insígnia mantêm seus mecanismos de retomada existentes. Item importante fica 2,5 s; insígnia usa o estojo e fica 3 s. Nenhuma dessas apresentações concede algo por desenhar ou completar uma animação.

## Conferência

| Suíte | Verificações | Falhas |
| --- | ---: | ---: |
| mural_result_checks.gd | 1548 | 0 |
| reward_layout_checks.gd | 892 | 0 |
| morro_result_presentation_checks.gd | 27 | 0 |
| key_item_banner_checks.gd | 28 | 0 |
| result_settlement_checks.gd | 8 | 0 |
| mural_battle_checks.gd, regressão da HUD de combate | 795 | 0 |

Total: **3.298 verificações**, incluindo a regressão da HUD de combate. A integração verifica save isolado real, XP não concedido na prévia, gravação antes da chamada de nível, proteção contra confirmação repetida, retorno ao mundo e persistência após reload. A suíte do Morro mantém estrelas/passagem e epílogo sem recibo duplicado. A entrega de documentos continua bloqueando comandos sob o banner e emitindo conclusão uma vez. Também se verifica que o foco retorna a Continuar quando uma tentativa de salvamento volta a funcionar.

Há **72 capturas nativas**: nove estados × quatro resoluções × texto 100/150%. Matriz: 1280×720, 1920×1080, 1024×768 e 1280×800. O teste legado de layout também executa sua matriz anterior, incluindo 2560×1080, em texto padrão. A galeria e integridade.json preservam dimensões e hashes. São fixtures dos consumidores reais sobre a arena do jogo, sem constituir playtest completo.

Os quatro relatórios padding-*.json somam **120 verificações nativas de glyphs**, sem falhas: títulos, subtítulos e nomes de momentos especiais dentro dos slots seguros. O restante do layout usa Containers, fontes nativas, viewport de rolagem inteiramente dentro dos 32 px e botão de continuar independente da rolagem. As capturas foram inspecionadas para corrigir conteúdo escondido por retratos, glyph de Enter exagerado, texto de retry estreito e celebração sob erro de gravação.

Teclado, mouse e controle foram exercitados por eventos nativos simulados; não houve controle físico. Texto ampliado pode exigir rolar o recibo por foco/setas ou mouse. Não foi feita certificação de acessibilidade nem teste completo de exportação. Persistem avisos ambientais de user://logs/cache/configuração do editor e avisos antigos de leitura direta de imagens da casa/professor, além de recursos retidos ao encerrar algumas suítes legadas.

As suítes com escrita usam diretórios únicos sob tmp/ do workspace; não alteram saves do jogador. A asserção legada sobre o NinePatch antigo foi atualizada para o conteúdo seguro do desenho Mural. Fontes e proveniência da arte ficam em art/ui/soulmonsters-v2/pip-136/.

Sem push, merge ou atualização no Linear. A aprovação artística do dono não é inferida do teste técnico. Próxima etapa: PIP-137, transições e sons.
