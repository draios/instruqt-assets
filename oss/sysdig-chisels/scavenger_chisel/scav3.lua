-- Chisel description
description = "Reconstruct a file using open syscalls"
short_description = "Scavenge everything!"
category = "I/O"

-- this version build the files and save them to disk
-- Check the file types with file *
-- lets create a key-value table in lua with the file name as key and the content data as the value, appended each time an event is encountered. 
-- and when we detect that the file has been closed, the content is flashed to disk

args={}

--table to store the content
files = {}

-- target event opening a file
-- get the name of the file
function on_event()
    local fname = chisel.request_field("fd.name")
    local fdata = chisel.request_field("evt.rawarg.data")
	local etype = evt.get_type()

    -- use it for every event
    local name = evt.field(fname)
    local data = evt.field(fdata)

	if etype == "open" or etype == "openat" then
		-- print("Opening file: " .. name ) -- we don't need this any more
        files[name] = "" --create entry for new file
    elseif etype == "write" then
        -- print("Writing file: " .. name .. ": " .. data)
        if files[name] then -- if file name exists
            content = files[name]
            files[name] = content .. data --concatenate&store existing&new_content
        end
    elseif etype == "close" then
        if files[name] then
            content = files[name]
            if string.len(content) > 0 then
                --print("Scavenging file  .. name")

                -- creates the 
                file_name = string.gsub(name, "/", "_")
                fp = io.output(file_name)
                io.write(content)
                io.close(fp)
            end
        end
    end
end


