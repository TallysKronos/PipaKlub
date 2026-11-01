# Primeiro exame — Rabiola Verde

Próxima etapa escolhida pela sequência da bíblia §6 e §7.2, depois de Tyler. O navegador estava desativado nas configurações do app; não foi possível ler ou atualizar o Linear nesta entrega. Nenhuma alegação de conclusão de uma issue remota.

## Implementado

`league_promotion.gd` exige conclusão histórica de Morro e Bambuzal, encontro concluído com Tyler, Lacertubo vencido e rabiola entregue à Nina. A entrega faz `award_into` dentro da mesma gravação que consome a rabiola da missão; não há uma segunda transação de prêmio. A categoria é permanente e não cai ao perder um título de bairro.

Certificado e autorização de empréstimo são itens únicos na mochila, junto das flags `leagueGreen` e `ninaGlideLoanAvailable`. A apresentação é reconhecida em operação separada (`leagueGreenSeen`), de modo que um fechamento após o prêmio retoma a apresentação sem concedê-lo novamente. A Carteira de Pipeiro mostra Rabiola Verde. O objetivo da história inclui o reconhecimento do exame.

Saves antigos com a rabiola já entregue continuam válidos. Após cumprir os demais requisitos, conversar novamente com Nina reconhece o exame sem repetir a missão. Não há promoção retroativa por simplesmente carregar um save antigo, nem requisito de ainda possuir os títulos.

Não foi criada uma Dona Cida provisória: a apresentação usa Nina e o registro da Carteira, sem introduzir novo design ou informação narrativa. Não se altera a geometria dos mapas.

## Limites explícitos

A autorização prepara o empréstimo; NÃO cria um Carcará transferível, não entrega uma cópia de Nina e não implementa a travessia de Planar. O trecho de ensino de Planar, animação e pontos de decolagem/chegada precisam de construção e validação próprias. As vagas do Varal e estágios de remonta propostos no quadro da bíblia também não foram implementados nesta etapa. O texto da apresentação informa que as funções ainda estão em preparação.

Não há promoção Azul/Vermelha/Dourada, novos bairros ou servidor online. Beira-Canal continua em breve até sua construção. Certificação apenas do save local, sem garantia antitrapaça online.

## Verificação

Godot 4.7.2: exame 19/0, fluxo nativo 7/0, ordem Nina 18/0, campanha 207/0, identidade 60/0. Total: 311 verificações sem falha. Testes de escrita falha, reentrada, recarga, requisitos ausentes, entrega atômica, repetição, reconhecimento de quest antiga e perda de título. A suíte de identidade ainda emite avisos preexistentes de carregamento direto das imagens do professor.

Capturas nativas 1280×720 em `documentation/qa/league-green-v1/`, revisadas: confirmação e carteira. Não foi testado controle físico, exportação de distribuição ou rede. Sem push/merge/deploy.
