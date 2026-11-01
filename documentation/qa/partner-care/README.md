# Kit de Remendo e cuidados do parceiro

Implementação local na campanha Godot, reaproveitando o kit Recorte e as animações existentes de todos os Soulmonsters disponíveis.

## Acesso e comportamento

- Equipe → Cuidar, em qualquer parceiro, ou Mochila → Kit de Remendo → Cuidar do parceiro. A Mochila também oferece um atalho de cuidados antes de possuir o primeiro kit.
- Disponível durante exploração; não abre um tratamento durante batalha ou montagem de uma pipa.
- Primeiro Kit de Remendo gratuito, retirado explicitamente na tela; concessão única por campanha, com recibo salvo. Depois, compra portátil por 12 moedas. Não há migração automática ou escrita em saves antigos ao iniciar o jogo.
- Sequência: limpar o papel → reforçar a armação → ajustar a linha. O parceiro reage, as ferramentas aparecem durante a interação e os passos concluídos ficam marcados.
- Fazer carinho ou clicar no espaço do parceiro provoca uma reação sem consumir itens nem conceder XP, moedas ou alterações de estatísticas.
- Concluir consome exatamente um kit e recupera linha e armação a 100%. Operação e recibo são persistidos juntos pelo Session/Store existentes. Não muda parceiro equipado, XP, bônus de construção ou condições dos demais parceiros.
- Voltar/Escape antes de concluir preserva o kit e a condição anterior. Falha ao salvar também preserva ambos e habilita nova tentativa da última etapa. Parceiro saudável não consome kit.
- Recuperação gratuita do professor e bancos continua disponível.

## Arquivos

`partner_care.gd`: regras e operação persistida. `partner_care_view.gd`: tela de cuidados. `front_end.gd`: acesso, navegação e ligações com o serviço. `hud_inventory.gd`: nome, descrição e uso do item.

`godot/assets/ui/kit-remendo.svg`: ícone vetorial criado para esta interface, contendo papel, varetas, cola e faixa de linha; não é uma imagem externa. Usa contorno escuro e as cores do kit existente. Criaturas utilizam as artes de campanha já disponíveis, sem redesenho ou geração nova.

## Verificação

- `partner_care_checks.gd`: 25 verificações, zero falhas. Inclui item ausente, retirada inicial, compra, moedas insuficientes, tratamento incompleto, cancelamento, parceiro inválido, reparo de parceiro secundário, gasto único, recibo idempotente, parceiro saudável, erro de armazenamento, retry da interface e recarga do save.
- `partner_care_integration.gd`: 19 verificações, zero falhas, em cada execução nativa 1280×720 e 960×720. Usa frontend real com Store isolado. Exercita Equipe, Mochila, retirada de kit, etapas, conclusão, retorno/Escape, estado saudável, foco após retirada e botões dentro da página. Capturas 01/02/03 em ambas as resoluções foram inspecionadas.
- `campaign_checks.gd`: 206 verificações, zero falhas.
- Ícone importado pelo editor Godot 4.7.2; execuções finais da interface não tiveram erro de recurso. O processo de importação emitiu um diagnóstico de safe-save das preferências do editor, sem impedir a importação.

Testes usam diretórios temporários isolados, sem abrir a campanha do jogador. Mouse/teclado são suportados pelos botões e foco nativo; não foi realizado teste com controle físico. A tela oferece interações discretas; não introduz fome, deterioração em tempo real ou obrigação diária.
