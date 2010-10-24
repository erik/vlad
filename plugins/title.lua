-- this plugin depends on the LuaSocket library (http://w3.impa.br/~diego/software/luasocket/)


PluginName = "title"
AdminOnly = false

http = require("socket.http")

function plugin() 
    url = args_
    
    -- http.request requires urls to have http://
    if not string.match(url, "http://.*") then
        url = "http://" .. url
    end
    
    
    content = http.request(url);
    
    if content == nil then
        privmsg(chan_, "URL not well formed, or nonexistent")
        return
    end
    
    title = string.match(content, "<title>([^<]*)</title>")
    
    privmsg(chan_, "Title of " .. nick_ .. "'s link: " .. title)
end

