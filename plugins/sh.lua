PluginName = "sh"
AdminOnly = true

function plugin()
    local p = io.popen(args_)
    result = p:read("*a")
        
    if result == "" then
        result = "No output."
    end
    
    privmsg(chan_, result)
end
