extends RefCounted
## Shared copy for slot cards and errors returned by the save service.
const RECOVERED := "Recuperamos um ponto anterior da sua jornada pelo backup. Confira seu progresso antes de continuar."
const BACKUP_AVAILABLE := "Backup disponível · a recuperação retoma um ponto anterior da jornada."
const ERRORS := {
	"bank_battle_changed":"O parceiro desta batalha antiga foi transferido ou liberado. Carregue um save de exploração; os arquivos foram mantidos.",
	"bank_pending":"A transferência ainda precisa concluir a gravação da campanha. Libere o acesso à pasta e tente novamente; o registro de propriedade foi preservado.",
	"bank_corrupt":"Não foi possível validar o depósito. Os registros foram preservados; nenhuma cópia antiga será usada automaticamente. Consulte o suporte.",
	"bank_future":"O depósito pertence a uma versão mais recente. Atualize o jogo para acessá-lo.",
	"bank_conflict":"Há gravações conflitantes do depósito. Feche outras instâncias e consulte o suporte antes de substituir os arquivos.",
	"bank_global_full":"O depósito global está cheio (20/20). Retire uma criatura antes de guardar outra.",
	"bank_campaign_full":"O banco desta campanha está cheio (30/30). Guarde uma criatura no depósito antes de receber outra.",
	"bank_active":"Este é seu parceiro ativo. Escolha outro parceiro antes de guardá-lo.",
	"bank_last":"Mantenha ao menos outro parceiro livre de vínculo de história nesta campanha.",
	"bank_story":"Este parceiro está emprestado ou vinculado à história e não pode ser transferido.",
	"bank_unsafe":"As transferências ficam disponíveis durante a exploração, fora de batalhas e cenas de história.",
	"bank_missing":"A criatura já mudou de lugar. Atualize a lista antes de tentar novamente.",
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
