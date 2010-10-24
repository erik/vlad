PluginName = "sh"
AdminOnly = true

function plugin()
    local p = io.popen(args_ .. " 2>&1")
    result = p:read("*a")
    
    result = string.gsub(result, "\n", "  ")
    result = string.gsub(result, "\r", "  ")
        
    if result == "" then
        result = "No output."
    end
    
    privmsg(chan_, result)
end
