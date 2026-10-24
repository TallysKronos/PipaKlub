# Publicação: Veredas e Lacertubo aprovado

Pedido: publicar no Render a montagem B ajustada e salva pelo responsável.
Arquivo incorporado: `lacertubo-estudo-b-encaixes-internos.soulgen (1).json`,
SHA-256 `9f4f52295b7514386c25c93ee54bfb6d40603603541f6e27a27c71dd4dde9ffd`.
Posições, pivôs, hierarquia e animações preservados no projeto e exportação.

## Dependência de banco

`supabase/migrations/028_park_guardian.sql`.
SHA-256 `f863be42f043461a0f8c64a89654f0dddebaa62f99db36b30cb573e13c936d49`.

Acrescenta a área `park-veredas` aos encontros, salva o checkpoint nesse mapa e
confirma a vitória de Lacertubo com XP idempotente. Reutiliza a reserva privada
de partidas e as permissões existentes. Não apaga dados, concede parceiros em
massa, muda senhas ou reinicia campanhas. Os encontros antigos continuam usando
as funções anteriores, encapsuladas e inacessíveis aos clientes diretamente.

Conferência de produção antes de publicar: migração ausente; 5 perfis, 68
parceiros, 1 montagem antiga. Produção corrente: `f9f7690`, Live no Render.

Ordem: aplicar 028 autorizada, conferir `verificar.sql`, publicar a mesma revisão
na `main`, aguardar Live do SHA correspondente e conferir health/arte publicada.
Não publicar a rota sem o suporte correspondente no banco.

Builds Worker e Pages concluídos. Exportação: seis ações, 127 quadros a 12 fps.
Sem testes automatizados ou de gameplay, conforme orientação do responsável.
O nível 15 permanece como referência inicial, ainda sem partida de balanceamento.

Situação inicial deste registro: pacote preparado; migração e deploy pendentes.
