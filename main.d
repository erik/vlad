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

Bot bot;
string prepend = "!";

void main(string[] args) {
    bot = new Bot("irc.freenode.net", 6667);
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
     
     string nick, user, host, type, chan, text;
     while(bot.alive()) {
         line = bot.recv();
         if(line.length > 0) {
             auto match = match(line, r);
             if(!match.empty) {
                 nick = match.captures[1];
                 user = match.captures[2];
                 host = match.captures[3];
                 type = match.captures[4];
                 chan = match.captures[5];
                 text = match.captures[6];
                 // temporary
                 if(text[0..1] == prepend) {
                     bot.privmsg(chan, "You said: " ~ text);
                     writeln(text[0..4]);
                     if(text[0..5] == prepend ~ "join")
                        bot.join(text[5..$]);
                 }
             }
         }
     }
 }
