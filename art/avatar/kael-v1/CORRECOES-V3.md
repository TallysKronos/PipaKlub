# Correções após a auditoria visual v3

23/10/2026. Implementação local; sem push ou deploy nesta etapa.

## Resultado e reavaliação

| Achado | Mudança | Resultado observado / limite |
|---|---|---|
| Desembarque descontínuo | `homeStairLanding()` compartilhado pelo jogo e bancada; sala (1424,1104), quarto (600,824). A prévia não usa mais o centro da sala ao voltar. | Subida e descida reproduzidas. Kael chega no piso junto à escada; os pontos são seguros, alcançáveis e permitem a interação de retorno. |
| Acabamentos misturados | Casca desenhada diretamente pela grade nativa do Iso Studio; novo desenho da escada com oito degraus, cores chapadas e contornos definidos; pipa na parede desenhada no plano isométrico. | Piso e paredes perderam a textura pintada. Escada combina melhor com sofá/mesas. Estante, bancos e outros detalhes menores ainda são os assets anteriores; não há aprovação de todo o kit por esta mudança. |
| Passada rígida | 16 quadros substituídos pelas fontes v5, com joelhos baixos e menos solado exposto. Escala única por folha, sem deformar braços ou pernas. | Eliminados os três avisos de variação de altura. A alternância anatômica continua insuficiente nas folhas geradas; tentativas com contato oposto e sapatos coloridos foram rejeitadas. Esta parte é melhoria parcial e ainda não recebe aprovação artística final. |
| Assento superficial | Contato foi de (550,812) para (526,788), mantendo a aproximação em piso seguro; sombra localizada no contato com a almofada. | Corpo mais para dentro do assento; sentar e levantar mantêm continuidade. Não foi adicionada deformação da almofada. |
| Combinações escuras | Rampa de cabelo Preto tem meios-tons frios mais separados do contorno. A paleta de pele Escuro permanece intacta. | Combinação Escuro/Preto/Verde-mata conferida nas quatro miniaturas e no cenário. Não é uma medição de acessibilidade por WCAG de ilustrações. |
| Bancada estreita | Zoom 100–400%, centralizar Kael, enquadrar ambiente inteiro, rolagem bidirecional; inicia em 200% abaixo de 500 px. Campos em uma coluna abaixo de 420 px. | Inspecionado em janela estreita: nomes completos visíveis, zoom e rolagem funcionais. A mudança é da ferramenta de revisão, não da câmera mobile do jogo. |
| Pouca identidade narrativa | Pipa artesanal na parede do estar, com painéis e rabiola alinhados ao plano da parede. | Complemento discreto; sem encher a área de circulação com props. |

## Verificação

- 442/443 testes na suíte completa. A falha remanescente é a anterior de `home-layout.test.mjs`, que consulta `art/kael-home-iso-v1/conferencia.json`. O relatório histórico não foi alterado para esconder a reprovação.
- 21/21 testes do fluxo `first-flight.test.mjs`, incluindo entrada, subida, retorno e preservação de conta; 10/10 testes de contatos/avatar após fortalecer o critério de desembarque (distância de até 82 e segmento desobstruído até a escada).
- Auditor dos 52 desenhos: sem avisos de altura e sem falhas de pivô, paleta, cabelo ou mochila. Isso não certifica naturalidade da passada.
- Build Worker e build Pages concluídos; `audit:world` aprovou a estrutura com 95 peças e 762 pontos de caminhada.
- Auditoria visual na bancada local: deslocamento ao sofá, assento, saída, subida, descida, desembarques, zoom e aparência alternativa. O clique no piso com a vista rolada e zoom de 300% também foi reproduzido: Kael levanta antes de seguir ao destino. A combinação Escuro/Preto/Verde-mata foi conferida e a aparência inicial restaurada. O fluxo autenticado em produção não foi exercitado.

## Reprodução e fontes

Execute `node scripts/extend-kael-avatar.mjs`, `node scripts/build-kael-home-actions.mjs`, `node scripts/polish-kael-interiors.mjs`, `node scripts/audit-kael-avatar.mjs`, `node build.mjs`, `node build-pages.mjs`.

Fontes selecionadas e copiadas ao repositório: `source/andar-se-v5.png`, `source/andar-ne-v5.png` e `source/escada-flat-v3.png`. Ferramenta: geração de imagens integrada, com referências do próprio projeto. Prompts e restrições em `source/REVISAO-V3-PROMPTS.md`. Normalização técnica: recorte de alpha, paleta-chave e escala uniforme, conservando a caixa 160×208 da escada. As regras e colisões do piso continuam vindo do Iso Studio. Evidências da inspeção em `.local/avatar-v3-evidence/`, além das capturas `revisao-v3-cores.png` e `revisao-v3-cenario.png` deste diretório.
