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
import std.regex;
import std.string;
import vlad.config;
import vlad.bot;

alias string[string] IRCLine;
alias void function(IRCLine) IRCcmd;


private Bot ircBot;

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
    line["chan"] = match.captures[5];
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
    ircBot = null;
}
 
IRCcmd get_command(string name) {
    switch(name) {
        case "say" : 
            return &cmdSay;
        case "quit" :
            return &cmdQuit;
        default:
            return &cmdDunno;
    }
}

void cmdSay(IRCLine line) {
    ircBot.privmsg(line["chan"], line["args"]);
}

//FIXME: only responds when there is a trailing space
void cmdQuit(IRCLine line) {
    ircBot.privmsg(line["chan"], "Quitting, bye!");
    ircBot.quit();
}

void cmdDunno(IRCLine line) {
    ircBot.privmsg(line["chan"], "Don't know command: " ~ 
        line["command"]);
}
