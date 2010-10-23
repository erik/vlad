#vlad
##An IRC bot written in D

This is a small IRC bot in D, in order to teach myself the language. 

It's not written to be the most elegant thing in the world, and I'm 
probably abusing D quite a bit. However, it is a nifty little bot that
can do some neat things.

This bot can run plugins that are either compiled into the executable 
itself (those in 'src/vlad/commands.d'), or be special Lua scripts that
can be modified while the bot is running, without the need to compile and 
restart (in 'plugins/'). 

The only requirement for Lua plugins is the presence of a function named 
`plugin`, which is what is run when the command, and a variable 
`PluginName`, which is what the plugin will respond to.
