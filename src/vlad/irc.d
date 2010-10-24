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
import std.string;
import core.thread;
import std.array;

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
    
    ///infinite loop, recieves data from socket, stores it in buffer
    void recv_loop() {
        Thread t = new Thread(&recv_loop_);
        t.start();
    }
    
    string recv() {
        if(recv_buf.empty) {
            return "";
        }
        
        string line = recv_buf[0];
        popBack(recv_buf);
        
        return line;
    }
    
    void clear_buf() {
        recv_buf.length = 0;
    }
    
    private:
    void recv_loop_(){
        char[256] ret = repeat("\0", 256);
        while(sock.isAlive()) {
            sock.receive(ret);
            if(ret == "") {
                break;
            }
            string str = cast(string) ret;
            str = replace(str, "\r", "\0");
            str = replace(str, "\n", "\0");
            
            string nstr = "";
            foreach(int c; str) {
                if(c != 0) {
                    nstr ~= cast(char)c;
                } else {
                    break;
                }
            }
            
            writeln("<<" ~ nstr);
            recv_buf ~= nstr;
            ret = repeat("\0", 256);
            Thread.sleep(500_000);
        }
        
    }
    string[] recv_buf;
    string server;
    ushort port;
    TcpSocket sock;        
}
