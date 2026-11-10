# Kael · overworld isométrico v2

O Kael em repouso, caminhada e corrida usa três folhas novas, com oito direções e oito quadros por direção. Cada célula tem 64 × 96 px. O repouso mede de 70 a 72 px de altura visível, com os pés fixos e o pivô original em (32, 94).

A ImageGen produziu cinco vistas de cabeça a partir do estudo diagonal e da prancha autoral. As três vistas laterais do lado oposto usam espelhamento da cabeça. Os corpos mantêm as passadas das folhas anteriores, reamostradas em pixels inteiros com encurtamento em perspectiva e paleta comum às três folhas. O script `normalizar.ps1` é executado a partir da raiz do repositório.

Os três ciclos entram pelo controlador compartilhado do avatar no Godot. As folhas próprias de salto, ação de item e montaria seguem com a arte de suas versões anteriores. A prévia local permite escolher a direção e comparar os três ciclos com os tempos usados no Godot.

Validação local no Godot 4.7.2. As três texturas importadas somam 192 quadros, todos dentro da célula e com silhueta conectada. Passaram 230 verificações de locomoção no Bosque, 11 de cidade e casa, 103 de mobilidade, 15 de barraca e 33 de montaria. A amostra em corrida de Veredas cobriu seis trajetos por rampa, patamar e ponte, além das duas transições do mapa.
A suíte completa de travessia em corrida também passou com 146 trajetos e 37.812 quadros de simulação, sem falhas.
