//      main.d
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

module vlad.main;

import std.stdio;
import std.socket;
import std.string;
import std.regex;

import vlad.bot;
import vlad.config;
import vlad.commands;

Bot bot;
string prepend = "!";

void main(string[] args) {
    read_config("vlad.config");
    bot = new Bot("irc.freenode.net", 6667, config_get("botname"));
    bot.connect();
    bot.join("#tempchan");
    core.thread.Thread.sleep(50_000_000);
    bot_loop();
}
 
 //TODO: split this into usable sections!
 void bot_loop() {
     bot.clear_buffer(); // clear out some connection leftovers     
     string line;
     auto r = regex(r"^:(.+)!(.+)@(\S+) (\S+) (\S+) :(.+)$");
     
     string[string] hash;
     while(bot.alive()) {
         line = bot.recv();
         if(line.length > 0) {
             auto match = match(line, r);
             if(!match.empty) {
                 hash["nick"] = match.captures[1];
                 hash["user"] = match.captures[2];
                 hash["host"] = match.captures[3];
                 hash["type"] = match.captures[4];
                 hash["chan"] = match.captures[5];
                 hash["text"] = match.captures[6];
                 // temporary
                 if(hash["text"][0..1] == prepend) {
                     bot.privmsg(hash["chan"], hash["nick"] ~ 
                        " said: " ~ hash["text"]);
                     writeln(hash["text"][0..4]);
                     if(hash["text"][0..5] == prepend ~ "join")
                        bot.join(hash["text"][5..$]);
                 }
             }
         }
     }
 }
