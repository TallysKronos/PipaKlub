# Correção do muro e da passagem

O usuário identificou falhas no topo do muro junto à bicicleta e cortes nas pernas do Kael no vão. A revisão estática anterior não detectou esses defeitos.

## Correções

- Refeito o capeamento contínuo do muro atrás da bicicleta.
- Recuperados os pixels do guidão, selim, quadro e metal das rodas a partir do recorte nativo original. O deslocamento anterior tinha recortado apenas parte desses detalhes e deixado resíduos em outras camadas.
- Retirados os resíduos das camadas do jardim e da base, inclusive a faixa que atravessava o alto do vão como uma viga.
- Ampliado o recorte interno da abertura, mantendo o ponto de apoio e as colisões existentes.
- Piso da passagem desenhado em camada própria, `soleira-portao.png`, apoiada no plano de chão. Ele não usa a profundidade vertical do muro.

A edição foi feita no Aseprite headless sobre a fonte `fontes/kit-integrado.aseprite`. O snapshot `antes.aseprite` e as capturas `antes-geral.png` e `antes-portao.png` preservam a versão anterior.

## Conferência

O teste de integração passou com 36 verificações e zero falhas, em slot descartável dentro do workspace. Além da entrada no interior e do retorno, a nova rotina percorre a passagem continuamente nos dois sentidos, renderizando o Kael e o companheiro ao longo do trajeto.

As capturas atualizadas estão em `../integracao/`. `passagem-contato.png` reúne seis momentos da entrada; os arquivos `passagem--1-*.png` e `passagem-1-*.png` preservam os momentos de entrada e saída. `portao-detalhe.png` mostra o trecho corrigido. O checklist automático está em `qa.json` nessa mesma pasta.

A comparação independente preferiu a versão corrigida, com 9,1/10 e nenhum achado bloqueante nos pontos marcados. Confirmou continuidade do muro, contornos completos da bicicleta e ausência da separação das pernas na sequência. Essa avaliação visual complementa o teste de travessia.
