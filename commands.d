//      commands.d
//      
//      Copyright 2010 Erik Price <erik.price16@gmail.com>
//      
//      This program is free software; you can redistribute it and/or modify
//      it under the terms of the GNU General Public License as published by
//      the Free Software Foundation; either version 2 of the License, or
//      (at your option) any later version.
//      
//      This program is distributed in the hope that it will be useful,
//      but WITHOUT ANY WARRANTY; without even the implied warranty of
//      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//      GNU General Public License for more details.
//      
//      You should have received a copy of the GNU General Public License
//      along with this program; if not, write to the Free Software
//      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
//      MA 02110-1301, USA.

module vlad.commands;

import std.stdio;
import std.socket, std.socketstream, std.stream;
import std.regex;
import std.string;
import std.socket;

import vlad.config;
import vlad.bot;

alias string[string] IRCLine;
alias void function(IRCLine) IRCcmd;


private Bot ircBot;

bool isAdmin(string nick) {
    foreach(admin; admins)
        if(nick == admin.toJSONString.get) return true;
    return false;
}


/// returns true if user is admin, false if not
bool shouldBeAdmin(IRCLine map) {
    if(!isAdmin(map["nick"])) {
        ircBot.privmsg(map["chan"], map["nick"] ~ ": you aren't an admin.");
        return false;
    }
    return true;
}

void handle_line(string input, Bot bot) {
    auto r = regex(r"^:(.+)!(.+)@(\S+) (\S+) (\S+) :(.+)$");
    auto prepend = config_get("prepend");    
    auto match = match(input, r);
    
    if(match.empty) {
       return;
    }
    
    IRCLine line;
    line["nick"] = match.captures[1];
    line["user"] = match.captures[2];
    line["host"] = match.captures[3];
    line["type"] = match.captures[4];
    line["chan"] = match.captures[5] == bot.name ? line["nick"] : 
        match.captures[5];
    line["text"] = match.captures[6].replace("\r\n", "\0");
    
    //FIXME: Doesn't respond to highlights unless there is no leading ws
    if(line["text"][0..1] == prepend || line["text"][0..bot.name.length+1] == (bot.name ~ ":")) {
        int offset = line["text"][0..1] == prepend ? 1 : bot.name.length+1;
        line["command"] = stripl(line["text"].indexOf(' ') == -1 ? 
            line["text"][offset..$] : line["text"].split[0][offset..$]);
        line["args"] = line["text"].split[1..$].join(" ");
    } else {
        return;
    }
    
    handle_command(line, bot);
}

void handle_command(IRCLine line, Bot bot) {
    auto cmd = get_command(line["command"]);
    
    ircBot = bot;
    cmd(line);
    bot = ircBot;
}
 
IRCcmd get_command(string name) {
    switch(name) {
        case "say" : 
            return &cmdSay;
        case "quit" :
            return &cmdQuit;
        case "down" :
            return &cmdDown;
        case "join":
            return &cmdJoin;
        case "part":
            return &cmdPart;
        case "whereareyou":
            return &cmdChans;
        case "sh":
            return &cmdSh;
        case "reload":
            return &cmdReload;
        default:
            return &cmdDunno;
    }
}

void cmdSh(IRCLine line) {
    if(!shouldBeAdmin(line))
        return;
    string command = line["args"];
    ircBot.privmsg(line["chan"], "Running command...");
    
    Bot tmp = ircBot;
    
    void run_sh_async(IRCLine l, Bot b) {
        string output;
        try {
            output = std.process.shell(command);
        } catch(Exception e) {
            output ~= "  Exception: " ~ e.toString();
        } finally {
            output = output.length == 0 ? 
                "Command completed successfully." : output;
            output = output.replace("\n", "  ");
            output = output.replace("\r", "  ");
            b.privmsg(l["chan"], output);
        }
    }
    
    void helper() {
        run_sh_async(line, tmp);
    }

    (new core.thread.Thread(&helper)).start();
}

void cmdSay(IRCLine line) {
    ircBot.privmsg(line["chan"], line["args"]);
}

void cmdQuit(IRCLine line) {
    ircBot.privmsg(line["chan"], "Quitting, bye!");
    ircBot.quit();
    //TODO: properly quit app
}

void cmdReload(IRCLine line) {
    if(!shouldBeAdmin(line))
        return;
        
    read_config("vlad.config");
    
    foreach(chan; config["chans"]){
          ircBot.join(chan.toJSONString.get);
    }
    
    ircBot.privmsg(line["chan"], "Reloaded.");
}

void cmdJoin(IRCLine line) {
    if(!shouldBeAdmin(line))
        return ;
    
    string chan = line["args"];
    ircBot.join(chan);
}

void cmdPart(IRCLine line) {
    if(!shouldBeAdmin(line))
        return ;
    
    string chan = line["args"];
    ircBot.part(chan);
}

void cmdChans(IRCLine line) {
    string channels = "";
    foreach(chan; ircBot.channels){
        channels ~= chan ~ " ";
    }
    ircBot.privmsg(line["chan"], "I am in: " ~ channels);
}

void cmdDunno(IRCLine line) {
    ircBot.privmsg(line["chan"], "Don't know command: " ~ 
        line["command"]);
}

void cmdDown(IRCLine line) {
    string baseURL = "downforeveryoneorjustme.com";
    string site = line["args"].split[0];
    string url = "/" ~ site;
    TcpSocket sock;
    Stream ss;
    
    try {
        sock = new TcpSocket(new InternetAddress(baseURL, 80));
        ss = new SocketStream(sock);
        ss.writeString("GET " ~ url ~ " HTTP/1.1\r\n"
            "Host: " ~ baseURL ~ "\r\n"
            "\r\n");
    } catch (Exception e) {
        writefln("Exception: ", e);
        ircBot.privmsg(line["chan"], "Sorry, the Internet is broken.");
        return;
    }
    
    char[] buf;
    
    uint down = -1;
    
    while(!ss.eof) {
        buf = ss.readLine();

        auto matches = match(cast(string)buf,
            regex(r"<title>([^<]+)</title>")) ;
            
        if(!matches.empty) {
            auto s = matches.captures[1];
            if(s == "It's just you.") {
                down = 0;
                break;
            } else if (s == "It's not just you!") {
                down = 1;
                break;
            }
        }
    }
        
    if(down == 1) {
        ircBot.privmsg(line["chan"], "It's not just you!");
    } else if(!down){
        ircBot.privmsg(line["chan"], "It's just you.");
    } else {
        ircBot.privmsg(line["chan"], "Uh oh, an error!");
    }
}
