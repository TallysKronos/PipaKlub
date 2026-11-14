# Consolidação local do PipaKlub

O projeto ativo está em `C:/Users/user/produto/pipa-club`, na branch `codex/unificacao-final`. A base `44b4865a` de `origin/claude/unificacao` reúne trailer, mapas, kits e o ritual de evolução. O commit `f7e65218` acrescenta as 40 animações de overworld revisadas, incluindo Azulão, Azulim e a família da Rai. O manifesto mantém 194 criaturas. O renderer suporta atlas com contagens distintas de quadros e mantém a escala da base consolidada.

Os 8 worktrees anteriores foram retirados do registro do Git. O Windows ainda mantém abertas duas pastas vazias, `pipa-club-integracao-atualizada` e `pipa-club-trailer-v2`. As branches anteriores continuam disponíveis no Git. Nenhuma referência remota foi alterada.

A pasta `C:/Users/user/produto/_unificacao-pipaklub/2026-11-13` contém `backup-verificado.json`, os arquivos identificados por SHA-256, os patches locais, os 13 arquivos de save copiados e os pacotes antigos em `builds`. Para extrair os arquivos de uma pasta anterior, execute `recuperar.py` com o nome original da pasta e um destino novo. A HUD experimental permanece no histórico e no arquivo de recuperação.

No projeto unificado, a suíte de animação passou em 4.242 verificações. O percurso visual no Godot com Azulão, Azulim e Raivela passou em 1.003 verificações. A rodada geral do Godot foi parcial, com 18 de 21 suítes executadas aprovadas, incluindo falhas e timeouts. A suíte web registrou 440 de 518 testes aprovados. Os logs e capturas estão em `tmp/unificacao-final/`.
