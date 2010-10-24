-- logging plugin
PluginName = "log"

ImplicitCommand = true

function plugin()
end

function implicit()

    file = io.open("log.log", "a+")
    
    if file == nil then
        return
    end
    
    time_str = os.date("%H:%M:%S", os.time())
    nick = nick_
    chan = chan_
    msg = text_
    
    log_str ="[" .. time_str .. "] " .. "(" .. chan .. ")" .. " " .. nick .. ": " .. msg .. "\n"
    
    file:write(log_str)
    file:flush()
    
end
