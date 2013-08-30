#!/usr/bin/ruby
# Copyright (c) 2013 joshua stein <jcs@jcs.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

require File.dirname(__FILE__) + "/lib/itunes"

if !ARGV[1]
  puts "usage: #{$0} <itunes playlist> <root directory of media>"
  exit
end

playlist = ARGV[0]
destdir = ARGV[1]
if !destdir.match(/\/$/)
  destdir << "/"
end

it = ITunes.new
pl = it.playlist(playlist)

albums = {}
pl.tracks.each do |track|
  artist = (track.compilation? ? "Various" : track.album_artist_or_artist)
  album = "#{artist} - #{track.album}"
  albums[album] ||= []

  albums[album].push track
end

# on ruby 1.9, Array#shuffle is a proper fisher-yates algorithm
albums.keys.shuffle.each do |album|
  # sort album tracks by disc number, then track number
  albums[album].sort_by{|t| sprintf("%02d", t.disc_number) << "-" <<
  sprintf("%02d", t.track_number) << "-" << t.name }.each do |t|
    # show the track relative to the playlist's gcd
    print destdir + t.safe_filename_without_gcd + "\r\n"
  end
end
