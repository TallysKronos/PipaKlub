extends RefCounted
## The OS releases the listener on exit, even after forced termination.
## Loopback only; never accepts connections or exchanges any profile data.
var _listener := TCPServer.new()

func acquire(profile_path: String = "user://") -> bool:
	if _listener.is_listening(): return true
	var path := ProjectSettings.globalize_path(profile_path).replace("\\", "/").simplify_path().trim_suffix("/")
	if OS.get_name() == "Windows": path = path.to_lower()
	var port := 49152 + (path.sha256_text().left(4).hex_to_int() % 16384)
	return _listener.listen(port, "127.0.0.1") == OK
