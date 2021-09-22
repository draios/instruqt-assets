-- Chisel description
description = "basic chisel"
short_description = "basic"
category = "misc"

-- Chisel argument list
args = {}

-- initialization callback
function on_init()
    chisel.set_event_formatter("")

    return true
end

-- Event parsing callback
function on_event()
    return true
end