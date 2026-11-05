extends RefCounted
## Shared copy for slot cards and errors returned by the save service.
const RECOVERED := "Recuperamos um ponto anterior da sua jornada pelo backup. Confira seu progresso antes de continuar."
const BACKUP_AVAILABLE := "Backup disponível · a recuperação retoma um ponto anterior da jornada."
const ERRORS := {
	"archive_pending": "Uma exclusão ou recuperação foi interrompida. As cópias de segurança foram preservadas. Libere o acesso à pasta e tente novamente para concluir a operação.",
	"campaign_removed": "Esta campanha foi excluída. Volte à lista de jornadas para começar outra ou desfazer a exclusão.",
	"corrupt": "Não foi possível abrir esta jornada. Os arquivos foram mantidos para recuperação. Consulte o suporte.",
	"future": "Esta jornada foi salva em uma versão mais recente. Atualize o jogo para continuar.",
	"unsupported": "O formato desta jornada é incompatível com esta versão do jogo. Consulte o suporte antes de substituir os arquivos.",
	"io_error": "Não foi possível acessar ou gravar a jornada. Confira o espaço disponível e a permissão da pasta, depois tente novamente.",
	"stale": "A jornada foi alterada. Volte ao menu e carregue novamente antes de salvar.",
	"occupied": "Esta jornada já existe. Escolha outro espaço para começar."
}
static func error(code: String) -> String:
	return ERRORS.get(code, "")
