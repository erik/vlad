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

void main(string[] args) {
    read_config("vlad.config");
    
    loadPlugins();
    
    string server = config_get("server");
    
    Bot bot = new Bot(server, config_get_numeric("port"), 
            config_get("botname"));
    bot.connect();
    foreach(chan; config["chans"]){
          bot.join(chan.toJSONString.get);
    }

    core.thread.Thread.sleep(50_000_000);
    bot_loop(bot);
    
}
 
 void bot_loop(Bot bot) {
     bot.clear_buffer(); // clear out some connection leftovers     

     string line;
     
     while(bot.isAlive()) {
         line = bot.recv();
         if(line.length) {
            handle_line(line, bot);
         } else {
             core.thread.Thread.sleep(2_500_000);
         }
     }
 }
