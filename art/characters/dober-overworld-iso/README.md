# Dóber e Kael montado no overworld

O acabamento usa uma grade próxima de um pixel por unidade na escala base do avatar. Dóber e Kael compartilham rampas de sombra e uma paleta fixa. A silhueta do Dóber tem contorno seletivo, com mais contraste nas bordas inferiores. As transparências parciais e os fragmentos soltos foram limpos por quadro.

A revisão cobre as oito vistas de repouso e os 16 ciclos de caminhada e corrida. Os recortes, apoios, pivôs e tempos das folhas originais são reutilizados. O editor de sprites do SoulGen abre as novas folhas estáticas pela configuração da montaria.

As folhas que o Godot usa ficam em `godot/assets/mounts/doberman-overworld-iso/`. Execute `pack.ps1` a partir da raiz para reconstruí-las a partir das folhas anteriores. A reconstrução sobrescreve as folhas publicadas, inclusive ajustes feitos pelo editor.

- [Repouso](repouso.png)
- [Caminhada](caminhada.png)
- [Corrida](corrida.png)
