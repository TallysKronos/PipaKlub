# Mormaço · integração V1

Fontes de identidade: forma C livre e possuído V2 aprovados. Recortes isolados gerados com image_gen, sem redesenho por código. Prompts em `prompts.json`; consumidor em `godot/assets/campaign/mormaco-v1/`.

`bound.png` e `free.png`: PNG RGBA 1536×1024, vazio alpha0, corpo até alpha254. Recortes de retrato e bounds declarados nos manifestos battle-ink. A tentativa inicial de atlas com quatro poses não foi adotada por inconsistência de enquadramento; a integração usa uma pose por estado, conforme outros chefes narrativos existentes.

Estas são **poses ilustradas**, não ciclo de sprites ou rig Soulgen completo. Repouso tem oscilação pequena e a libertação mistura as duas texturas em1,2s quando movimento reduzido está desligado. Ataque/dano/vitória reutilizam a pose; o feedback de combate e a indicação do jato pertencem ao sistema da arena. Não afirmar animação articulada do Mormaço nesta versão.

Formas e conceitos anteriores preservados. Integração não implica captura do guardião.
