# Ateliê local v1 — verificação

Implementado em `tools/atelie/`. Inicialização: `npm run atelier`, porta padrão 5210, bind em 127.0.0.1. Nenhuma dependência nova e nenhum acesso a banco/produção.

Validação em 18/10/2026:

- Build do servidor, build Pages e validação ESM aprovados.
- 233 testes passaram (228 do projeto com chibis + cinco testes do Ateliê).
- Biblioteca carregou as 26 peças originais e seis folhas.
- Colocação de banco no mapa, propriedades e restauração por IndexedDB após reload verificadas no navegador.
- Kael caminhou da entrada ao caminho da escadaria usando a navegação real.
- PNG local importado, exibido no seletor de folhas da bancada.
- Recorte de 128×128 criado pela UI na sessão de auditoria e removido com Desfazer; Refazer ficou disponível.
- Exportação real pela UI gerou `morro-do-sol-bancada-jogo.zip`. Python zipfile abriu sem erros de CRC; contém project.json, blockout.tmj, art.json, kit.json, README e as seis imagens referenciadas.
- Sem erros de console na sessão isolada de auditoria.

O trabalho da bancada principal foi preservado ao terminar os testes numa origem separada (porta 5211). A aba principal permanece em 5210. Não foi feito commit, push ou deploy.

Limites funcionais e instruções de integração estão no README do Ateliê. O editor compõe e recorta imagens; não gera arte por IA. Exporta objectgroups Tiled compatíveis com o contrato atual, não tilelayers/GIDs. Projetos novos têm piso e entrada válidos, sem encontros inventados. Novas texturas de piso usam a propriedade opcional ground_frame, mantendo o padrão antigo quando ausente.
