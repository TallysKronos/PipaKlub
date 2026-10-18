# Auditoria de consistência visual — Papel e Bambu

Data: 17/10/2026. Base: bfbc017. Branch: feature/ui-kit-consistente.

## Diagnóstico

O projeto tinha quatro camadas visuais coexistindo: CSS original em index.html, painéis azuis de courtyard.css, atlas pintado do HUD e o kit Switch. A última camada só decorava parte dos controles. O quintal, diálogos e o contêiner do menu ainda mantinham fundos e textos do padrão anterior.

## Mapeamento por superfície

| Fluxo | Peças encontradas | Aplicação |
|---|---|---|
| Quintal | Identidade, objetivo, rodapé, comandos, nomes dos destinos | Resource, tooltip e botões do kit; fundo das margens verde neutro |
| Menu principal e submenus | Janela, seis destinos, voltar, listas | Window; preserva ícones e janelas dos seis destinos já implementados |
| Professor e primeiro voo | Diálogo, mensagens, continuar/voltar/pular | Speech, texto verde e botões; preserva cenário e sprites |
| Escolha inicial | Cartões, seleção, confirmação | Portrait-card com contorno de seleção e botões |
| Cidade | Identidade, painel do bairro, nomes dos marcos, voltar/entrar | Resource, window, rótulos de papel; mantém marcos sobre o mapa |
| Coleção e Dex | Janela, ações e retratos | Window e botões; retratos compactos preservam sua geometria especializada |
| Conta | Perfil, clube, histórico, configurações | Mesma janela e ações; conteúdo continua em páginas separadas |
| Amigos e regras | Sheets e comandos | Window e botões comuns |
| Fazenda | Janela, paginação, ações | Window; paginação quebra linha em telas estreitas |
| Invocação | Janela, cartões vistos, rabiolas, comandos | Window, portrait-card e botões; palco mágico preservado |
| Trocas | Janela, criar/entrar/ofertar/confirmar/cancelar | Window e botões; animação celeste permanece como palco |
| Escola | Janela, tour e orientação durante treino | Window e speech |
| Trilhas | Janela e comandos | Window e botões; mapa e insígnias mantidos |
| Resultado e desafio diário | Modal e ações | Window e botões; linhas de recompensa mantidas |
| Avisos e consentimento | Toast e painel de privacidade | Tooltip e speech |
| Entrada sem conta | Comandos e sheets | Mesmos botões; painel inicial pintado existente preservado |
| Batalha | HUD, leque de ações e barra de comandos | Mantidos: já têm atlas pintado e componentes do kit |

## Regras de implementação

- ui-kit-policy.js centraliza os seletores de superfícies. ui-kit-client.js só adiciona atributos: não recria botões, listeners ou estado de conta.
- CSS usa os PNGs existentes por suas variáveis com cache hash. Bordas usam os insets do manifest, sem esticar cantos.
- Camadas antigas de decoração são escondidas apenas nos elementos migrados.
- Botões primários, secundários e desabilitados usam peças próprias. Foco visível e movimento reduzido continuam disponíveis.
- Observador acompanha apenas inserções de elementos; animações por style não provocam reaplicação a cada frame.
- Não usar o estilo de botão de ação em retratos da Dex, marcos do mapa, destinos do cenário ou controles de combate.

## Verificação e limites

/menu-audit inclui 15 telas em 7 tamanhos: 320×568, 390×844, 568×320, 768×1024, 1104×700, 1440×900 e 1920×1080. Usa conta fictícia e bloqueia mutações econômicas. Verifica limites horizontais, diálogos, altura dos painéis e recorte dos retratos.

Essa matriz verifica a geometria dos estados de entrada; não representa um teste de cada estado de rede, uma troca concluída ou uma invocação com consumo de item. Esses fluxos mantêm seus testes funcionais separados. Efeitos mágicos, medidores de combate, céu e cores de raridade são elementos intencionais, não resíduos do painel azul.

Prévia visual manual: quintal autenticado, menu principal e fluxo de parceiro/professor. A auditoria não aplica migração de banco, não altera economia e não publica em produção.

## Resultado dos testes

- Build do servidor e da versão estática concluídos; artefato ESM validado.
- Suíte funcional: 165 testes aprovados, zero falhas.
- Foram adicionados testes da política de skins e da decoração de controles inseridos dinamicamente, sem observar mudanças de animação.
- Primeira matriz visual: quatro casos com erro em telas pequenas; corrigidos cartões da Dex tratados indevidamente como botões de ação e paginação da fazenda sem quebra de linha.
- Revisão manual adicional: menu principal, escola e cidade. Ajustados textos longos da escola, fechar e nomes extensos dos bairros.

- Segunda matriz concluída: 105 casos, zero erros de geometria. Resultado completo: outputs/ui-kit-matriz.json no diretório da conversa.

## Revisão do mapa
A composição com fundo desfocado foi substituída por um atlas de papel e bambu: uma superfície única, mapa emoldurado à esquerda e legenda do bairro à direita. Referências: Paper Mario (https://www.mariowiki.com/File%3ATTYDNS_Palace_of_Shadow_Map.jpg) e manual oficial de Ni no Kuni (https://ssl.level5.co.jp/game/ninokuni/manual/pc/page04.html). Build e artefato validados; revisão manual da navegação local.
