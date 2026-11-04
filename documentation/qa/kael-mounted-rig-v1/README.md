# Verificação do piloto de Kael montado

- Captura nativa Godot 4.7.2, Compatibility, 1280 × 720: `mounted-se.png`.
- `godot/tests/mounted_rider_checks.gd`: 14 verificações, zero falhas.
- `godot/tests/mount_checks.gd`: 684 verificações, zero falhas.
- Node: model, editor, mounted-rig e server — 21 testes, zero falhas.
  Editor repetido após ajuste de recuperação: 12 testes no conjunto
  editor + mounted-rig, zero falhas.
- API real: página, módulo e GET `/api/mounted-rig` responderam HTTP 200.
- Testes DOM não substituem inspeção de layout no navegador. Automação
  de navegador desativada nesta sessão; não houve validação visual dessa UI.
- Sem alteração de saves de campanha, publicação ou exportação de executável.
