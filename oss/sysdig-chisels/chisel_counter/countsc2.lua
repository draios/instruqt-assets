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

-- Event parsing callback
function on_event()
	print(syscallname)
	return true
end