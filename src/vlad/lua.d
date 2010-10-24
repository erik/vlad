//      lua.d
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

module vlad.lua;

import std.stdio;
import std.file;
import std.string;

import vlad.bot;
import vlad.irc;
import vlad.config;
import vlad.commands;

import luad.all;

LuaState[string] luaPlugins;
alias string[string] IRCLine;

///Load all the plugins from specified directory
void loadPlugins(string dir="plugins") {
    foreach(string file; listdir(dir)) {
        auto lua = new LuaState;
        string name = file;
        LuaFunction plugin;
        
        lua.openLibs();
        try {
            lua.doFile(dir ~ "/" ~ file);
        } catch (luad.error.LuaError e) {
            writeln("WARNING: Lua error from " ~ file ~ ": " ~ e.toString);
            continue;
        }
        
        try {
            plugin = lua.get!LuaFunction("plugin");
        } catch(luad.error.LuaError e) {
            writeln("WARNING: Plugin " ~ file ~ " disabled, no `plugin` function");
            continue;
        }        
        try {
            name = lua.get!string("PluginName");
        } catch(luad.error.LuaError e) {
            writeln("WARNING: Plugin " ~ file ~ " disabled, no `PluginName` defined");
            continue;
        }
        
        luaPlugins[name] = lua;
        writeln("Loaded: " ~ name);
    }
}


///Call a Lua plugin. 
void callPlugin(string name, Bot bot, IRCLine line) {
    auto lua = name in luaPlugins;
    if(lua == null) {
        bot.privmsg(line["chan"], "Don't know command: " ~ name);
        return;
    }
    
    bool adminOnly = false;
    try {
        adminOnly = lua.get!bool("AdminOnly");
    } catch(luad.error.LuaError e) {
        // Meh
    }
    
    if(adminOnly && !shouldBeAdmin(line)) {
        return;
    }
    
    void privmsg(string chan, string msg) {
        bot.privmsg(chan, msg);
    }
    
    void action(string chan, string msg) {
        bot.action(chan, msg);
    }

    // since we are setting *globals* here, the trailing _ is used so
    // that the variable is unique
    lua.set("command_", line["command"]);
    lua.set("nick_", line["nick"]);
    lua.set("host_", line["host"]);
    lua.set("type_", line["type"]);
    lua.set("chan_", line["chan"]);
    lua.set("text_", line["text"]);
    lua.set("args_", line["args"]);
    lua.set("privmsg", &privmsg);
    lua.set("action", &action);
    
    auto plugin = lua.get!LuaFunction("plugin");
    try {
        plugin();
    }catch(luad.error.LuaError e) {
        writeln(e.toString());
        bot.privmsg(line["chan"], "Lua command encountered an error");
        return;
    }
    

}
