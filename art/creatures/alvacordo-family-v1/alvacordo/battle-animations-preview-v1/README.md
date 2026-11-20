# Alvacordo — ataque e reação de dano

Player de revisão local das duas animações192×192. Ataque10frames/950ms; dano8frames/720ms.24cores, pivôproposto(96,181), direçõesleft/rightespelhadas. Fontes e atlases nas pastasirmãs battle-attack-v1 e battle-damage-v1. Nenhum asset aprovado do overworld foi modificado.

As tags executam uma vez. A repetição com intervalo é somente uma opção do player, não alteração das tags do atlas. Há velocidade1×/0,5×/0,25×, passo por quadro, escala nativa/integer e fundos claro/magenta/escuro.

validar.py confirmou dimensões, alpha binário, espelho exato, duração e igualdade dos frames inicial/final com o master aprovado. validacao.json mantém os resultados. A prévia foi conferida por sintaxe JavaScript e caminhos locais; não foi testada em navegador nem em jogo nesta entrega.

Revisão independente: dano8/10 sem bloqueadores; ataque7,5/10 após reconstrução localizada das cordasF6. A orientação muda rapidamente para perfil no contragolpe; avaliar em reprodução antes de integrar. Os PNGs são derivados das poses H3 e normalizados para a paleta aprovada; o ataque não é um redesenho manual completo das poses.

Não houve integração, alteração de código de combate, commit ou push.
