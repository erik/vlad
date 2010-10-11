//      bot.d
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

module vlad.bot;

import std.stdio;
import vlad.irc;

class Bot {
   
    this(string server, ushort port, string nick="vladbot", string realname="vladbot") {
        this.server = server;
        this.nick = nick;
        this.port = port;        
        this.user = nick ~ " * * :" ~ realname;        
    }
    
    void connect() {
        irc = new IRC(server, port);
        irc.recv_loop();
        irc.user(user);
        irc.nick(nick);
        alive = true;
        
        void ping_loop() {
            if(isAlive) {
                core.thread.Thread.sleep(1200_000_000);
                foreach(string chan; chans) {
                    irc.send("PING " ~ chan);
                }
                ping_loop();
            }
        }
        
        (new core.thread.Thread(&ping_loop)).start();
    }        
    
    void join(string chan) {
        chans ~= chan;
        irc.join(chan);
    }
    
    void privmsg(string chan, string message) {
        irc.privmsg(chan, ":" ~ message);
    }
    
    bool isAlive(){
        return alive && irc.alive();
    }
    
    string recv(){
        return irc.recv();
    }
    
    void clear_buffer(){
        irc.clear_buf;
    }
    
    string name(){
        return nick;
    }
    
    void quit() {
        alive = false;
        irc.quit;
    }
    
    private:
    string server;
    string nick;
    string user;
    string[] chans;
    IRC irc;
    ushort port;
    bool alive;
}

