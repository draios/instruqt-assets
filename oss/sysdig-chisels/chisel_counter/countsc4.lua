-- Chisel description
description = "counts how many times the specified system call has been called"
short_description = "syscall count"
category = "misc"

-- Chisel argument list
args = 
{
	{
		name = "syscall_name", 
		description = "the name of the system call to count", 
		argtype = "string"
	},
}

-- Argument notification callback
function on_set_arg(name, val)
	syscallname = val
	return true
end

-- Initialization callback
function on_init()
	-- Request the fileds that we need
	ftype = chisel.request_field("evt.type")
	fdir = chisel.request_field("evt.dir")
	
	return true
end

count = 0

-- Event parsing callback
function on_event()
	if evt.field(ftype) == syscallname and evt.field(fdir) == ">" then
		count = count + 1
	end
	
	return true
end

-- End of capture callback
function on_capture_end()
	print(syscallname .. " has been called " .. count .. " times")
	return true
end