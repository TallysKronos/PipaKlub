# Evidências nativas — montaria e missão

- `01-zeca-quest.png`: apresentação da missão, aceitar/recusar.
- `02-apito-reward.png`: banner do Apito de Elo, recompensa já salva.
- `03-mounted-city.png`: Kael montado na cidade com o parceiro presente.

Godot 4.7.2, Compatibility, 1280 × 720. Produzidas pelo teste isolado
`godot/tests/mount_city_flow_checks.gd -- --capture`.

19 verificações sem falhas. Usa posicionamento controlado do jogador para
testar o fluxo rapidamente; as últimas verificações passam por `interact()`
dos NPCs e pelo sinal do botão do inventário. Não acessa saves de produção.
