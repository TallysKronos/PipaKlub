# Atalho local: depois da primeira montagem

Execute `npm run dev:trades` e abra http://127.0.0.1:5194/. Entre como visitante ou em uma conta local. Na faixa TESTE LOCAL, escolha a primeira pipa e clique em **Pular início · teste**. A página recarrega na casa do Sr. Assis, após a abertura, o primeiro voo e a montagem inicial.

A função `skipLocalOpening` está em `scripts/local-skip-opening.mjs`. Usa uma transação no banco local e as regras existentes de nascimento, rabiola e conclusão do tutorial. Registra a montagem concluída, consome a rabiola e equipa o parceiro escolhido. Uma escolha já iniciada é preservada; campanhas completas não são reiniciadas e chamadas repetidas não geram novos parceiros. Batalhas e outras montagens em andamento impedem a operação.

Disponível apenas no servidor de teste local. A rota POST /local/skip-opening exige sessão local e origem correspondente. Não cria migração nem endpoint de produção. O teste `node --test local-skip-opening.test.mjs` verifica conclusão, persistência, consumo do item, equipamento, isolamento e repetição sem duplicação.
