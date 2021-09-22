-- Chisel description
description = "Reconstruct a file using open syscalls"
short_description = "Scavenge everything!"
category = "I/O"

args={}
 
-- target event opening a file
function on_event()
    -- we get the event type
	local etype = evt.get_type()

	if etype == "open" or etype == "openat" then
		print("Opening file")
	end
end