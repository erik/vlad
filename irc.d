//      irc.d
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

module vlad.irc;

import std.stdio;
import std.socket;
import core.thread;

class IRC {

    this(string server, ushort port) {
        this.server = server; 
        this.port = port;
        
        sock = new TcpSocket(new InternetAddress(server, port));
    }
    
    void send(string message)
        in {
            assert(message.length > 0);
        }
        body {
            writeln(">>" ~ message);
            sock.send(message ~ "\r\n");
        }
    
    void privmsg(string chan, string message) {
        send("PRIVMSG " ~ " " ~ chan ~ " " ~ message);  
    }
    
    void nick(string nick) {
        send("NICK " ~ nick);
    }
    
    void user(string user) {
        send("USER " ~ user);
    }
    
    void join(string chan) {
        send("JOIN " ~ chan);
    }
    
    ///infinite loop, recieves data from socket, stores it in buffer
    void recv_loop() {
        Thread t = new Thread(&recv_loop_);
        t.start();
    }
    
    string recv() {
        if(recv_buf.length == 0) {
            return "";
        }
        
        string line = recv_buf[recv_buf.length - 1];
        recv_buf.length = 0;
        
        return line;
    }
    
    void clear_buf() {
        recv_buf.length = 0;
    }
    
    private:
    void recv_loop_(){
        char[256] ret = std.string.repeat("\0", 256);
        while(sock.isAlive()) {
            sock.receive(ret);
            if(ret == std.string.repeat("\0", 256)) {
                break;
            }
            write("<<" ~ std.string.chop(cast(string)ret));
            recv_buf ~= std.string.splitlines(cast(string)ret);
            ret = std.string.repeat("\0", 256);
        }
        
    }
    string[] recv_buf;
    string server;
    ushort port;
    TcpSocket sock;        
}
