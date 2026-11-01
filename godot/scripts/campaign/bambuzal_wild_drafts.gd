extends RefCounted
## Provisional encounters only. Not a final species/summoning contract.
const IDS=["rascunho-bicho-pau","rascunho-joaninha"]
static func choose(roll:float)->String:return "rascunho-bicho-pau" if roll<.45 else "mata" if roll<.85 else "rascunho-joaninha"
static func name_for(id:String)->String:
	return {"rascunho-bicho-pau":"Bicho-pau de Vareta [rascunho]","rascunho-joaninha":"Joaninha-pião [rascunho]"}.get(id,id)
