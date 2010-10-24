-- this plugin depends on the LuaSocket library (http://w3.impa.br/~diego/software/luasocket/)


PluginName = "title"
AdminOnly = false
ImplicitCommand = true


http = require("socket.http")

function findTitle(url)
    -- http.request requires urls to have http://
    if not string.match(url, "http://.*") then
        url = "http://" .. url
    end
    
    content = http.request(url);
    
    if content == nil then
        return nil
    end
    
    title = string.match(content, "<title>([^<]*)</title>")
    
    return title
end

function plugin() 
    title = findTitle(args_)
    
    if title == nil then 
        privmsg(chan_, "URL not well formed, or nonexistent")
    end
    
    privmsg(chan_, "Title of " .. nick_ .. "'s link: " .. title)
end

function implicit()
    b, e = string.find(text_, "http://%S+")
    
    if not b or not e then
        return
    end
    
    title = findTitle(string.sub(text_, b, e))
    
    if title then       
        privmsg(chan_, "\"" .. title .. "\"")
    end
end
