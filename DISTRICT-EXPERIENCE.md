# Etapa 2 — Cidade e encontros do bairro

18/10/2026. Implementação local na branch feature/ui-kit-consistente. Sem deploy.

## Alterações

- Atlas com insígnias menores, nomes contextuais e seleção em destaque.
- Próximo encontro identificado no comando de entrada do bairro; bloqueio respeita o progresso existente.
- Entrada pelo mapa abre somente os cinco encontros daquele bairro, com apresentação ilustrada do campeão.
- Visão geral das trilhas preservada; fechar o bairro remove o filtro e permite voltar ao mapa.
- Textos identificam encontro 1–5 e campeão; comando de batalha explicita o desafio.
- Dados de maestria ficam fora do primeiro contato com o bairro.
- Detalhes do encontro rolam separadamente; ação de iniciar permanece acessível.
- Seleção preserva foco após reconstruir a lista de encontros.

## Verificação

Suíte completa: 168 testes passaram antes do ajuste final do painel rolável. Testes da interface rodados novamente após esse ajuste, com resultado registrado no log local. Build e artefato validados. Matriz ampliada para 126 casos: zero erros geométricos na rodada; o ajuste final da área rolável recebeu revisão manual adicional.

Navegador: quintal → atlas → Morro do Sol → apresentação de Mikka → seleção do campeão bloqueado → primeiro encontro disponível → início real de batalha local contra Zeca → menu da partida → saída para o quintal. Nenhuma vitória ou recompensa foi simulada. O teste usou conta e servidor locais.

## Limites

Não implementa os nove bairros ainda em preparação, nem novas regras de títulos, economia ou recompensas. Não representa uma campanha concluída ou validação em controle físico. Mantém a direção do atlas e prepara a continuidade da revisão de combate, resultados e retorno à jornada.
