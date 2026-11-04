extends RefCounted
## The ending is presentation state; the world checkpoint and rewards stay intact.
const RECEIPT := "demo-ending-v1"

static func completed(saved: Dictionary) -> bool:
	var player: Dictionary = saved.get("player", {})
	var flags: Dictionary = player.get("flags", {})
	# Also recognizes journeys completed before the ending screen existed.
	return player.get("journey", {}).get("phase", "") == "complete" and flags.get("guardianDefeated", false) and flags.get("ninaReturned", false)

static func pending(saved: Dictionary) -> bool:
	return saved.get("checkpoint", {}).get("kind", "") == "world" and completed(saved) and not saved.player.flags.get("demoEndingSeen", false)

static func acknowledge(session: Node) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if not completed(saved): return {"status": "wrong_step"}
	saved.player.flags.demoEndingSeen = true
	return session.commit_operation(RECEIPT, saved.checkpoint, saved.player)
