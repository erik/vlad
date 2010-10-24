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
import vlad.lua;

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
    
    //FIXME: Doesn't respond to highlights
    if(line["text"][0..1] == prepend) {
        line["command"] = stripl(line["text"].indexOf(' ') == -1 ? 
            line["text"][1..$] : line["text"].split[0][1..$]);
        line["args"] = line["text"].split[1..$].join(" ");
    } else if (line["text"][0] == '\1'){
        line["text"] = line["text"][1..$-1];
        handle_ctcp(line, bot);
        return;
    } else {
        return;
    }
    
    handle_command(line, bot);
}

void handle_ctcp(IRCLine line, Bot bot) {
    auto r = regex(r"([A-Z]+)\s+(.*)");
    auto match = match(line["text"], r);
    
    auto cmd = match.captures[1];
    auto rest = match.captures[2];
    writeln(cmd);
    writeln(rest);
    
    switch(cmd) {
        case "PING":
            bot.privmsg(line["nick"], "\1PONG " ~ rest ~ "\1");
            break;
    }
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
        case "action":
            return &cmdAction;
        case "quit" :
            return &cmdQuit;
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
        case "mute":
            return &cmdMute;
        case "unmute":
            return &cmdUnmute;
        default:
            return &cmdCallLua;
    }
}

void cmdAction(IRCLine line) {
    ircBot.action(line["chan"], line["args"]);
}

void cmdMute(IRCLine line) {
    if(!shouldBeAdmin(line))
        return;
    ircBot.privmsg(line["chan"], "Muted.");
    ircBot.mute(line["chan"]);
}

void cmdUnmute(IRCLine line) {
    if(!shouldBeAdmin(line))
        return;
    ircBot.unmute(line["chan"]);
    ircBot.privmsg(line["chan"], "Unmuted.");
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
    
    loadPlugins();
    
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

void cmdCallLua(IRCLine line) {
    callPlugin(line["command"], ircBot, line);
}
