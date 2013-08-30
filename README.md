A couple scripts for maintaining a directory of music files (probably located
on a USB music player or SD card) from an iTunes playlist.

Requires the `appscript` gem.

###itunes-rsync.rb
Query a given iTunes playlist, build a scratch directory symlinking all files
of that playlist into it, then run `rsync` from the scratch directory to the
path given.

**Note:** `rsync`'s `--delete` option is used, so it will delete any files in
the given path that are not found in the playlist.

Usage: `ruby itunes-rsync.rb "ipod (auto)" /Volumes/music/iTunes/`

###playlist_album_shuffle.rb
Query a given iTunes playlist, organize all tracks into albums, shuffle the
albums, and then print the filename of each track in each album (in its
original track order) to STDOUT, relative to the path given.

Mimics the album shuffle functionality of iTunes and older iPods and can be
used to create a few album-shuffled `.pls` playlists of a given list of tracks
for players that don't natively support album shuffle.

**Note:** The path for the second argument is the path relative to all media as
it would be mounted by the player.  Nothing is saved to that path and the
output is all done to STDOUT.

Usage: `ruby playlist_album_shuffle.rb "ipod (auto)" /mnt/SD1/iTunes/ > /Volumes/AK100/album\ shuffle\ 1.pls`

###License

Copyright (c) 2009, 2012, 2013 joshua stein <jcs@jcs.org>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
