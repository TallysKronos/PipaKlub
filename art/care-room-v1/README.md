# Cantinho do parceiro · v1

Implementado no Godot como uma sala de cuidados em tela cheia, acessível durante a exploração por **Equipe → Cuidar** ou **Mochila → Kit de Remendo → Usar**.

## Direção e arquivos

- `godot/assets/care-room-v1/quarto-atelie.png`: cenário novo, 1672×941, gerado pela ferramenta de imagem integrada. Prompt integral em `background-prompt.txt`. Quarto-ateliê brasileiro, sol da tarde, papel, bambu e plantas; centro e tapete livres. A imagem é o cenário desta interface, sem personagens ou botões pintados nela.
- Oito SVGs originais: mão aberta, carinho, apontar, paninho, papel/cola, carretel, coração e cesta. Fundo transparente, 96×96, contorno escuro e cores do cenário.
- Seis conjuntos articulados **já existentes e aprovados**: Rabbito, Mata, Azulão, Raio de Sol, Lacertubo e Carcará. As texturas e os pivôs vêm do Soulgen; não são novos redesenhos. Cada `rig.json` registra `careSource`. Registro em `rigs.json`.
- `tools/prepare-care-room.py` prepara cópias locais das peças aprovadas, os vetores e chama `prepare-care-room-basica.mjs` para Carcará. Não regenera nem edita o cenário PNG.

## Interação

O parceiro anda até destinos no chão livre, para, descansa e volta a explorar. Chamar escolhe um destino; cuidar o conduz até o tapete, sem teletransporte. Corpo, cabeça, orelhas, asas e rabiola têm movimentos pequenos a partir das peças disponíveis; a direção horizontal acompanha o destino.

1. Pegue o primeiro kit grátis ou compre um por 12 moedas.
2. Escolha Paninho e espere o parceiro chegar ao tapete. Segure e arraste sobre ele.
3. Aplique Papel e cola com três toques sobre o parceiro.
4. Segure o Carretel sobre ele até terminar.

Carinho e Passear funcionam sem kit. O parceiro continua passeando depois do reparo. A condição aparece ao inspecioná-lo ou cuidar dele.

Mouse: clicar, arrastar e segurar. Teclado: Tab percorre ferramentas, setas movem a mão dentro do ambiente, Enter confirma/segura, Esc volta. Os mesmos comandos `ui_*` atendem ao controle; não houve teste com controle físico. A preferência de movimento reduzido retira balanços e saltinhos, mantendo o deslocamento necessário para compreender a ação.

## Segurança do progresso

`partner_care.gd` continua responsável pelo kit, pelas moedas e pela recuperação. O componente visual apenas apresenta as etapas. O kit só é consumido com o reparo completo salvo. Sair antes preserva o kit; falha de gravação permite repetir o ajuste final. Não modifica XP nem troca o parceiro equipado. Testes usam saves isolados em `tmp/`.

## Verificação

- `partner_care_checks.gd`: 25 verificações de economia, cancelamento, falha de gravação, idempotência e persistência.
- `partner_care_integration.gd`: 51 verificações no cenário real da campanha; navegação, gestos, destinos, foco, cursor, seis rigs e enquadramento. Execução nativa em 1280×720 e 960×720; capturas em `documentation/qa/care-room-v1/`.
- `campaign_checks.gd`: 206 verificações de regressão da campanha.

O chão livre é uma região delimitada desta sala, não um sistema de navegação por móveis. O quarto é compartilhado pelos parceiros. As animações desta versão são leves e articuladas na mesma vista aprovada; não representam sprites novos em oito direções.
