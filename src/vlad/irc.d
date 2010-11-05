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
import std.socket, std.socketstream;
import std.string;
import core.thread;
import std.array;

class IRC {

    this(string server, ushort port) {
        this.server = server; 
        this.port = port;
        
        sock = new TcpSocket(new InternetAddress(server, port));
        sockStream = new SocketStream(sock);
    }
    
    void send(string message)
        in {
            assert(message.length > 0);
        }
        body {
            writeln(">>" ~ message);
            sock.send(message ~ "\r\n");
        }
    
    void privmsg(string chan, string message) 
    in {
        assert(alive());
    }
    body {
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
    
    void part(string chan, string reason) {
        send("PART " ~ chan ~ " :" ~ reason);
    }
    
    bool alive(){
        return sock.isAlive();
    }
    
    void quit() {
        send("QUIT :bye!");
        sock.close();
    }
    
    string recv() {
        if(sock.isAlive()) {
            string s = cast(string)this.sockStream.readLine();
            writeln("<<" ~ s);
            return s;
        }
        return null;
    }
    
    private:

    string server;
    ushort port;
    TcpSocket sock;  
    SocketStream sockStream;      
}
