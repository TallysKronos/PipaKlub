# Acampamento antes dos cuidados

O acesso por Equipe ou Itens agora volta ao mapa salvo antes de abrir o bichinho virtual.

## Sequência

1. O movimento é bloqueado; Kael faz o gesto de braço e lança o Kit de Remendo numa trajetória curta.
2. O acompanhante chega à frente da entrada e entra enquanto a lona sobe.
3. A barraca se ergue ao redor de Kael, fecha a entrada e somente então a tela escurece.
4. Sob a tela preta, o modo de cuidados é construído; o preto desaparece suavemente.
5. Voltar ou Escape devolve o jogador ao overworld no mesmo ponto salvo.

Animação normal: cerca de três segundos até a tela preta. Movimento reduzido: sequência abreviada, sem o arco do lançamento. A barraca é arte vetorial 2D desenhada em camadas, com paleta de lona clara e azul-petróleo, reforços, costuras, cordas e motivo de pipa. O gesto reutiliza os sprites existentes do Kael; o projétil reutiliza o ícone do kit. Não foi criado um novo spritesheet de lançamento.

## Contratos preservados

Montar a barraca não consome itens, cobra moedas ou repara o parceiro. A conclusão das três interações continua sendo a única operação que consome o kit e aplica o reparo. O acampamento não altera colisões, geometria ou dados permanentes do mapa. Cliques duplicados e comandos de movimento/menu ficam bloqueados durante a transição. Objetos e poses temporárias são limpos ao terminar a cena.

## Verificação

- `care_camp_checks.gd`: 15 verificações, zero falhas. Retorno ao mundo antes dos cuidados, ordem das fases, bloqueio de movimento, clique duplicado, ausência de consumo antecipado, posição de retorno, modo reduzido e Escape.
- `partner_care_checks.gd`: 25 verificações, zero falhas.
- `partner_care_integration.gd`: 50 verificações, zero falhas. Tratamento completo, cancelamento, obtenção de kit, consumo e parceiros existentes. O runner headless ainda registra duas instâncias ObjectDB retidas ao encerrar; sem erros de execução ou falhas de verificação.
- Capturas nativas a 1280×720 das fases em `01-kit-lancado.png` a `05-cuidados.png`. Conferidas a abertura real e a lona fechada sem acompanhante atravessando a barraca.

Os testes usam save isolado. A validação visual registrada é na Praça da Campeã; não constitui revisão visual de todos os mapas e posições possíveis de acampamento.

O pacote interno `godot/exports/demo-test-2026-10-31/` foi atualizado e executado fora do projeto. A barraca e a entrada no cuidado foram exercitadas com renderização nativa: saída 0, log sem erros. Evidência: `barraca-pacote.png`. Continua sendo o pacote de teste com runtime local.

## Correção na Vila — 01/11/2026

O log da partida real mostrou acesso inválido a `park.path` em `neighborhood_view.gd`: a cidade herda o controlador do cais e não tem essa propriedade. A chamada ocorria depois de pausar o personagem, interrompendo a cena antes de criar a barraca. O teste anterior na Praça da Campeã não cobria esse controlador.

A transição agora limpa uma rota apenas quando o controlador a possui. Na Vila, também reconhece o nó `partner` do acompanhante, em vez de esperar o nome `companion` usado nos parques.

Novo teste nativo `care_city_checks.gd`: seis verificações, zero falhas, cobrindo entrada a partir da equipe, execução da barraca na Vila, abertura do cuidado, retorno com movimento, preservação do kit e da posição. Captura `barraca-vila.png`. Regressão da Praça da Campeã: quinze verificações, zero falhas.

O mesmo teste foi executado com o executável e o PCK atualizados, fora do projeto: seis verificações, zero falhas, saída 0, sem erros no log. Dados do jogador preservados; teste em save isolado.
