# Fachada da Casa do Kael integrada

15/11/2026. Aplicada no projeto principal `pipa-club`, após autorização para calibrar os acessos e substituir a fachada.

## Resultado

- Seis recortes da casa e uma bicicleta independente em `godot/assets/campaign/kael-house-v2/`, sem ampliação individual. Muros, pilares, portão, correio e piso agora usam a geometria aprovada no estudo v3.
- O vão continua alinhado a (4,4, 18,2). A folha fixa foi substituída pelo [componente animado independente](PORTAO-ANIMADO.md): abre na aproximação e fecha após Kael e companheiro se afastarem. A bicicleta permanece fora da passagem. Validação atual: 51 checks, zero falhas.
- A porta da pintura fica ligada ao ponto de aproximação (5,8, 16,2). O caminho do portão até ela foi percorrido nos dois sentidos. O corpo bloqueado termina em v 15,55, deixando a soleira acessível.
- O retorno da campanha continua em HOME (4,4, 17,4). A entrada usa o fluxo existente de `kael-home`, e a saída do interior continua usando o checkpoint original.
- Cerca, correio, dois vasos, árvore e flores antigos que se duplicavam no jardim foram retirados da montagem. Os muros mantêm colisão, com o vão do portão livre.
- O fechamento frontal tem planos de profundidade separados para suas duas faces. As capturas mostram o Kael atrás do muro dentro do jardim e à frente dele na calçada.

O quadro aprovado foi mantido em pixels nativos. A porta desenhada tem cerca de 75–80 px, diferente dos 92 px inicialmente propostos no blockout. A calibração usa a soleira dessa pintura aprovada e a escala atual dos personagens do runtime, sem esticar o prédio. A fonte editável integrada está em `../fontes/kit-integrado.aseprite`; a fonte anterior e seus recortes continuam preservados.

## Correção do renderizador

`pier_visibility.gd` recriava todos os meshes com filtro linear e repetição habilitada, ignorando a configuração original. Agora mantém `texture_filter` e `texture_repeat` de cada peça. Isso conserva nearest na nova fachada e a configuração própria dos demais assets.

## Verificação

`qa.json` registra **39 verificações e zero falhas**. O teste carregou o frontend e a cena de campanha, percorreu portão, jardim e soleira com o resolvedor real de movimento, acionou a interação que abre o interior e acionou a saída para retornar à cidade. Também conferiu os filtros após a reconstrução das faces, as colisões e o alinhamento do apoio do portão.

Foi usado um slot descartável em `.local/qa/casa-kael-v2-<id>`, dentro do workspace. Nenhum save pessoal foi aberto ou alterado. O slot usa um parceiro de teste para representar a fase posterior à criação do primeiro Soulmonster, necessária pelo fluxo existente de viagens. Não foi alterada essa regra de campanha.

Capturas

- `01-geral.png` e `06-retorno.png`, contexto da Vila.
- `02-portao-fora.png`, passagem aberta.
- `03-muro-dentro.png` e `04-muro-fora.png`, oclusão dos dois lados.
- `05-soleira.png`, aproximação e ação de entrar.
- `comparativo.png`, concept, fonte calibrada e captura da campanha.

A revisão visual independente atribuiu 9/10, sem achados bloqueantes nas cinco posições avaliadas. Ela não substitui o teste de movimento descrito acima.

Para reproduzir os testes e as capturas

```powershell
& './.local/godot/Godot_v4.7.2-stable_win64_console.exe' --path godot --script tools/casa_kael_v2_integracao.gd --rendering-method gl_compatibility
& './.local/godot/Godot_v4.7.2-stable_win64_console.exe' --path godot --script tools/casa_kael_v2_comparativo.gd --rendering-method gl_compatibility
```

Os avisos de log/cache de `user://` no ambiente de execução não impediram as capturas ou os testes. Os interiores da casa continuam nas versões existentes, e seus blockouts v2 permanecem como a próxima etapa de arte. Não houve exportação de build ou push nesta entrega.

## Revisão da passagem após feedback

Corrigidos o capeamento e os resíduos da bicicleta, removida a faixa sobre o vão e adicionado um piso próprio com profundidade de chão. A rotina de QA agora também registra a travessia contínua nos dois sentidos. Veja `passagem-contato.png`, `portao-detalhe.png` e o relatório em `../revisao-portao/README.md`. As capturas anteriores estão preservadas nessa pasta de revisão.

## Solução atual — volumes v3

Após a crítica de ambiguidade entre muro e piso, o dono aprovou o estudo de volumes e sua aplicação. A versão atual substitui o fechamento raster por faces completas de muro e pilares no Godot, com tampa, sombra lateral, portão aberto e correio apoiados na geometria. A passagem tem piso cinza na mesma cota da calçada. A bicicleta é um prop raster independente.

O relatório atual está em `../portao-geometria-v3/aplicacao/README.md`. O teste foi atualizado para 39 verificações aprovadas e as capturas desta pasta mostram essa solução. O antigo `fachada-calibrada.png` permanece como fonte histórica de pintura; os volumes do portão agora são construídos no runtime e não estão incorporados nessa imagem. As fontes raster atuais são `kit-portao-v3.aseprite` e `bicicleta-portao-v3.aseprite`.
