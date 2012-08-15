===CARTS MOD for MINETEST-C55===
by PilzAdam

Version 30

Introduction:
This mod adds carts to minetest. There were rails for so long in minetest
but no carts so that they were useless. But this mod brings what many
players all over the world wanted for so long (I think so...).

How to install:
Unzip the archive an place it in minetest-base-directory/mods/minetest/
if you have a windows client or a linux run-in-place client. If you have
a linux system-wide instalation place it in ~/.minetest/mods/minetest/.
If you want to install this mod only in one world create the folder
worldmods/ in your worlddirectory.
For further information or help see:
http://wiki.minetest.com/wiki/Installing_Mods

How to use the mod:
Read the first post at http://minetest.net/forum/viewtopic.php?id=2451

Configuration:
(all variables are in init.lua)
line 4: MAX_SPEED => the maximum speed of the cart
line 9: TRANSPORT_PLAYER => transport the player like a normal item 
		 (this is very laggy NOT RECOMMENDED)
line 13: SOUND_FILES => a table with all soundfiles and there length. To
		 add your own files copy them into carts/sounds (only .ogg files
		 are supported) and add there name (without ".ogg") and there
		 lenght (in seconds) to the table.
line 21: SOUND_GAIN => the gain of the sound.
line 27: RAILS => blocks that are treated as rails.

License:
Sourcecode: WTFPL (see below)
Sound: WTFPL (provided from Ragnarok)
Graphics: CC0 (provided from kddekadenz)

See also:
http://minetest.net/

         DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                    Version 2, December 2004

 Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

 Everyone is permitted to copy and distribute verbatim or modified
 copies of this license document, and changing it is allowed as long
 as the name is changed.

            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. You just DO WHAT THE FUCK YOU WANT TO. 
