# Auditoria do primeiro ciclo — 21/10/2026

## Ambiente e alcance

Campanha nova de Kael no banco local separado `.local/buyer-audit-20261021`, porta 5203. A campanha da prévia principal, porta 5201, foi preservada. Sem Supabase de produção, publicação ou alterações no Git remoto.

Teste pelo navegador, usando botões visíveis e teclas reais, sem injetar vitórias, posicionar atores pelo console ou avançar checkpoints artificialmente. O controle físico não foi testado: a navegação por analógico e os comandos de controle estão cobertos pela simulação dos testes automatizados.

## Percurso realizado

1. Tela inicial → transmissão Jamile/Gollia → decisão de Kael.
2. Caminhada no quarto, mesa, encaixe da vareta e nascimento do projeto físico.
3. Entrada da mãe, aniversário e apresentação central da Rabiola Antiga.
4. Retorno à mesa, invocação e nome padrão Rabbito confirmado.
5. Escada, sala da casa e saída para a Rua dos Ventos.
6. Orientação principal → casa do Sr. Assis → cinco lições com Nozinho.
7. Movimento até o círculo, ataque confirmado, recuperação de energia, habilidade ativa durante acerto, esquiva, rebicada e corte final de Nozinho.
8. Conclusão confirmada na conta → mapa da cidade → Praça da Chegada → conversa/apresentação do desafio de Zeca. A passagem seguinte continuou bloqueada pela vitória.
9. Menu Save e bancos: manual vazio, automático disponível, um Rabbito no banco do save.
10. Transferência preparada e aplicada: save 0/30, global 1/20, mesma cópia de Rabbito.
11. Recarregamento do navegador retomou a Praça da Chegada junto de Zeca, sem repetir história ou treino.
12. Reinício do servidor local e nova autenticação também preservaram posição, campanha e Rabbito global. Conferidos novamente pela interface.

Após a continuação solicitada, o duelo real contra Zeca também foi exercitado:

13. Primeira tentativa: derrota por 0 a 2, resultado confirmado, retorno ao mapa mantendo a passagem bloqueada.
14. Segunda tentativa: derrota por 1 a 2; o botão de revanche retornou corretamente à apresentação do encontro.
15. Terceira tentativa: vitória por 2 a 1, sem alterar adversário, atributos ou resultado pelo console. Usados mouse e Espaço no fluxo normal.
16. O servidor confirmou duas estrelas, 23 moedas com bônus da primeira vitória e 120 XP para o parceiro.
17. Retorno à Praça da Chegada mostrou Zeca vencido, carteira com 23 moedas e passagem liberada.
18. Caminhada pelo objetivo e travessia automática chegaram à Escadaria da Sombra. A missão passou a ser encontrar Bia. A Laje dos Ventos permaneceu bloqueada pela vitória contra Bia.

## Problemas corrigidos

### Sessões locais se sobrescreviam entre portas

Cookies não são separados por porta pelo navegador. As prévias antigas abertas em localhost podiam invalidar a conta da auditoria durante a história. O adaptador local agora usa cookies com prefixo da porta e aceita somente suas próprias credenciais. O fluxo de autenticação de produção permanece inalterado. Um teste cobre isolamento, rejeição de credenciais antigas e exclusão correta dos cookies da sessão.

### Placar encobria o alvo do tutorial

Na janela de teste de 854 × 612, o placar superior direito cobria o círculo do primeiro exercício. O primeiro voo agora esconde esse placar; o HUD de parceiro e os comandos permanecem disponíveis. O restante das partidas mantém seu placar.

### Porta da introdução ainda exigia interação

Escada e saída agora mostram setas azuis e avançam quando o personagem caminha até o limiar. E continua disponível como alternativa. A instrução também passou a citar as setas do teclado. Teste novo verifica passagem andando sem apertar o botão de interação; os testes existentes cobrem o caminho e ambas as saídas.

### Mensagem dos saves ignorava o automático

O painel dizia que nenhuma posição manual estava salva mesmo com o automático disponível, sem mostrar a data do slot 0. Agora apresenta os dois slots explicitamente com suas datas ou “vazio”. Verificado pela interface após reiniciar o servidor.

## Reinício da campanha e preservação

A exclusão real foi verificada nos testes PostgreSQL/PGlite com banco descartável, sem apagar a campanha de uso pelo navegador. A cobertura confirma que os 20 espaços globais são preservados, os checkpoints de ambos os slots são limpos, o banco do save é descartado conforme a seleção, um novo Rabbito pode nascer e prêmios únicos não são duplicados. A interface de transferência e sua persistência foram exercitadas no navegador.

## Pontos para a próxima rodada

- Reduzir a área do quadro do professor em janelas baixas, mantendo instrução, energia, trajetória e comandos sempre visíveis.
- Unificar a identificação da franquia: apresentação usa Soulmonsters e partes da abertura ainda dizem PipaKlub.
- Transformar os atalhos de lugares da introdução em instruções contextuais mais discretas, mantendo acesso por controle e teclado.
- Testar o percurso com controle físico Xbox/PlayStation, especialmente nomeação do parceiro e entrada de confirmações textuais.
- Próximo percurso de conteúdo: Bia e os demais encontros, retornos entre setores e conclusão do bairro; verificar também replay sem repetir bônus da primeira vitória.

## Evidências e validação

Captura da interface com Rabbito global e datas dos slots: `../outputs/auditoria-comprador-banco-global.png` (fora da pasta do repositório, na pasta de resultados da conversa).

Build do servidor e build Pages executados. Os logs da execução completa e dos testes posteriores ficam em `../work/buyer-full-suite.log`, `../work/buyer-door-tests.log` e `../work/buyer-final-suite.log`.
