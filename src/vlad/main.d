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
import vlad.lua;

//TODO: clean up main

int main(string[] args) {
    read_config("vlad.config");
    
    loadPlugins();
    
    string server = config_get("server");
    
    Bot bot = new Bot(server, config_get_numeric("port"), 
            config_get("botname"));
    bot.connect();
    
    core.thread.Thread.sleep(5_000_000); // wait for it ...

    foreach(chan; config["chans"]){
          bot.join(chan.toJSONString.get);
    }    

    bot_loop(bot);
    return 0;    
}
 
 void bot_loop(Bot bot) {
     string line;
     
     while((line = bot.recv()) !is null) {
         handle_line(line, bot);
     }
     return;
 }
