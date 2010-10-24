-- this plugin depends on the LuaSocket library (http://w3.impa.br/~diego/software/luasocket/)

PluginName = "down"
AdminOnly = false

http = require("socket.http")

-- simply screenscrapes downforeveryoneorjustme.com for the title of the page

function plugin()
    base = "http://downforeveryoneorjustme.com/"
    
    if string.match(args_, "http://.*") then
        args_ = string.match(args_, "http://(.*)")
    end
    
    url = base .. args_
    
    
    content = http.request(url);
    
    if content == nil then
        privmsg(chan_, "An error occured.")
        return
    end
    
    title = string.match(content, "<title>([^<]*)</title>")
    
    privmsg(chan_, args_ .. ": " .. title)
end
