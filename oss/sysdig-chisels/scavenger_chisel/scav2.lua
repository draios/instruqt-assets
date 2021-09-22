-- Chisel description
description = "Reconstruct a file using open syscalls"
short_description = "Scavenge everything!"
category = "I/O"

-- this version gets the content!
-- Execute with sysdig -r trace.scap -c scavenger "evt.dir=<"
-- In every write operation there is a data field that contains the full binary payload extracted by the kernel, but this is quite difficult to read


args={}

-- target event opening a file
-- get the name of the file
function on_event()
    -- get the name of file descriptor (fd)
    local fname = chisel.request_field("fd.name")
    -- get the written content
    local fdata = chisel.request_field("evt.rawarg.data")
    -- we get the event type
	local etype = evt.get_type()

    -- use it for every event
    local name = evt.field(fname)
    local data = evt.field(fdata)

	if etype == "open" or etype == "openat" then
		print("Opening file: " .. name )
    elseif etype == "write" then
        print("Writing file: " .. name .. ": " .. data)
    end
end

