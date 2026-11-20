# Vegetação top-down — piloto

Seis peças de vegetação: capim-rabiola A/B, arbusto-folha-pipa A/B e bromélia-do-vento A/B. Os nomes são propostas visuais, não lore ou itens implementados. Formas de folhas remetem à pipa sem transformar toda vegetação em papel costurado.

Referências de câmera/acabamento: Kael e Alvacordo overworld aprovados. Câmera elevada, contorno escuro, sombras em blocos e mesma densidade de pixel. Paleta vegetal própria em verdes de quintal, petróleo, amarelo de sol, flores coral/creme.

Destino: jogo top-down no Godot, conforme instrução atual do usuário. Neste piloto, produzir PNGs RGBA separados e atlas, fontes editáveis e prévia. Objetos de vegetação, não pisos seamless nem autotile de terreno. Não montar mapa nem substituir runtime nesta etapa.

Proposta técnica: células64×64, raiz em(32,52), dimensões ocupadas variadas para preservar escala. Sem terreno nem sombras pintadas no PNG. Pivôs e colisões precisam ser conferidos no mapa antes de integrar.
