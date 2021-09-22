-- Chisel description
description = "counts how many times the specified system call has been called"
short_description = "syscall count"
category = "Misc"

-- Chisel argument list
args = {}

-- Event parsing callback
function on_event()
	print("event!")
	return true
end