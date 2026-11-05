extends RefCounted

const RESCUES := {
	"kronasta-coracao-a": {
		"guard":"Capanga: A moça quase soltou o nó com os dentes. Agora ninguém chega perto.\n\nNina: Kael, o fio passa pelo carretel dele. Se ele perder o controle, eu consigo soltar o resto.\n\nKael: Então segura firme mais um pouco.",
		"bound":"Nina: Estou bem. O nó aperta quando eu puxo. Preciso que você distraia o capanga.",
		"freed":"Nina: Pronto. A linha afrouxou e eu consegui tirar a mão. Ouvi o Bando falar de outra prisioneira na galeria seguinte.\n\nKael: A Mikka. Eu vou atrás dela.\n\nNina: Vai. Eu fico aqui até conseguir mexer os dedos direito.",
	},
	"kronasta-coracao-b": {
		"guard":"Capanga: O chefe mandou vigiar a curva. Você pode voltar pelo mesmo caminho que veio.\n\nMikka: Kael, ele enrolou a ponta na fivela. Se você vencer, eu alcanço o fecho.\n\nKael: Entendi. Deixa a linha comigo.",
		"bound":"Mikka: Quase soltei a fivela. Sempre que ele olha pra cá, puxa a linha de novo.",
		"freed":"Mikka: Ufa. Meus óculos sobreviveram. A Jamile fez barulho de propósito pra trazer os guardas pra longe de mim. Levaram ela adiante.\n\nKael: Você consegue voltar até a Nina?\n\nMikka: Consigo. Vou buscar ela e a gente alcança você.",
	},
	"kronasta-coracao-c": {
		"guard":"Grampo: Rato já entrou na câmara. Platyx, segura a linha.\n\nJamile: Grampo, olha pra ele. Ele está tremendo desde que você amarrou minhas mãos.\n\nGrampo: É só mais um duelo. Vai, Platyx.",
		"after":"Jamile: Grampo e Platyx entraram na câmara. A porta está livre.",
		"bound":"Jamile: Estou com as mãos presas. Quando a linha cair, afaste o carretel do alcance dele.",
		"freed":"Grampo: Platyx, volta aqui. Eu mandei você puxar.\n\nGrampo: Toda vez que você baixava a cabeça, eu fingia que era um sim.\n\nGrampo: Tá bom. Nunca mais vou puxar por você. Vamos soltar a Jamile juntos?\n\nGrampo: Vou tentar fazer o Rato parar. Platyx, vem comigo?",
	},
}

const DOOR := "Jamile: Daqui em diante, fica de olho no altar. Se Rato usar a chave, talvez a gente fique preso do lado de dentro.\n\nEntrar na Câmara do Elo bloqueia a saída até Eremor ser derrotado."
const CHIEF := "Grampo: Rato, para. Olha pro Platyx. Eu achei que podia escolher por ele. Você ainda pode largar essa chave.\n\nRato: Passei anos vendo parceiros irem embora quando bem entendiam. Com o Elo, eu posso criar um que fique.\n\nKael: Se ele é obrigado a ficar, você já decidiu tudo por ele. Largue a chave.\n\nRato: Venha tirar da minha mão."
const BETRAYAL := "Kael: Acabou, Rato. A chave.\n\nRato: Eu prometi um duelo. Não prometi entregar nada.\n\nTyler: Kael, ele está indo pro selo!"
const EVACUATE := "Tyler: Nina, Mikka, Jamile, comigo! Grampo, segura a retaguarda."
const AWAKENED := "Kael: Eremor! Olha pra mim. Você fica aqui."
const REMATCH := "Tyler: A passagem ainda aguenta. Respira, confere a linha e me avisa quando estiver pronto.\n\nKael: Dessa vez eu seguro Eremor aqui."
const VICTORY := "Kael: A linha parou de puxar.\n\nNo altar, só restaram os pedaços da chave do Elo. O Rato sumiu pela fenda durante o desabamento.\n\nTyler: Todo mundo passou. Vem, Kael.\n\nGrampo: Platyx, pronto pra sair?"
const LOST_GUARD := "Kael: Minha linha cedeu. Vou me recompor e volto pra soltar você."
const LOST_CHIEF := "Rato: Enquanto a chave estiver comigo, o altar é meu.\n\nKael: Ainda dá tempo. Vou tentar de novo."
