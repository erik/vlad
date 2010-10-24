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
import std.string;

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
                auto cs = this.channels;
                foreach(string chan; cs) {
                    irc.send("PING " ~ chan);
                }
                ping_loop();
            }
        }
        
        (new core.thread.Thread(&ping_loop)).start();
    }        
    
    void join(string chan) {
        if(!inChan(chan)) {
            chans ~= chan;
            irc.join(chan);
        }
    }
    
    void part(string chan, string reason="Leaving") {
        chan = chomp(chan);
        
        if(inChan(chan)) {
            string[] newChans;
            foreach(c; chans) {
                if(c.icmp(chan)) {
                    newChans ~= c;
                }
            }
            this.chans = newChans;
        }
        irc.part(chan, reason);
    }
    
    bool muted(string chan) {
        foreach(c; mutes) {
            if(c == chan)
                return true;
        }
        return false;
    }
    
    void mute(string chan) {
        if(!muted(chan)){
            mutes ~= chan;
        }
    }
    
    void unmute(string chan) {
        if(muted(chan)) {
            string[] newMutes;
            foreach(c; mutes) {
                if(c != chan) {
                    newMutes ~= c;
                }
            }
            mutes = newMutes;
        }
    }
    
    void privmsg(string chan, string message) {
        if(!muted(chan))
            irc.privmsg(chan, ":" ~ message);
    }
    
    void action(string chan, string message) {
        if(!muted(chan)) {
            this.privmsg(chan, "\1ACTION " ~ message ~ "\1");
        }
    }
    
    bool isAlive(){
        return alive && irc.alive();
    }
    
    bool inChan(string chan) {
        foreach(c; this.chans) {
            if(!c.icmp(chan))
                return true;
        }
        return false;
    }
    
    string[] channels(){
        return chans;
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
    string[] mutes;
    IRC irc;
    ushort port;
    bool alive;
}

