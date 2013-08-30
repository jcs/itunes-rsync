#!/usr/bin/env ruby
# Copyright (c) 2009, 2012, 2013 joshua stein <jcs@jcs.org>
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

require "rubygems"
require "appscript"
$: << File.dirname(__FILE__)
require "appscript_itunes_fix"

class ITunes
  def initialize
    @as = Appscript.app.by_name("iTunes", ITunesFix)
    @_playlists = {}
  end

  def playlist(name)
    @_playlists[name] ||= Playlist.new(self, name)
  end

  def as_playlist(name)
    @as.playlists[name]
  end
end

class Playlist
  def initialize(itunes, name)
    @itunes = itunes
    @as_playlist = @itunes.as_playlist(name)
  end

  def tracks
    @tracks ||= @as_playlist.file_tracks.get.map{|t| Track.new(self, t) }
  end

  def total_bytes
    tracks.map{|t| File.size(t.location) }.inject(:+)
  end

  # figure out where all tracks are stored by checking for the greatest common
  # directory of every track
  @_gcd = nil
  def gcd
    return @_gcd if @_gcd

    @_gcd = ""

    locs = self.tracks.map{|t| t.location }.sort_by{|p| p.length }
    (0 .. locs[0].length).each do |pos|
      try = locs[0][0 ... pos]

      ok = true
      locs.each do |loc|
        if loc[0 ... try.length] != try
          ok = false
          break
        end
      end

      if ok
        @_gcd = try
      else
        break
      end
    end

    @_gcd
  end
end

class Track
  attr_accessor :album_artist, :artist, :album, :compilation, :disc_number,
    :location, :name, :track_number

  def initialize(playlist, track)
    @playlist = playlist

    @album_artist = track.album_artist.get.to_s
    @artist = track.artist.get.to_s
    @album = track.album.get.to_s
    @compilation = !!track.compilation.get
    @disc_number = track.disc_number.get.to_i
    @location = track.location.get.path.to_s
    @name = track.name.get.to_s
    @track_number = track.track_number.get.to_i
  end

  def compilation?
    @compilation
  end

  def album_artist_or_artist
    @album_artist.strip == "" ? @artist : @album_artist
  end

  # restrict pathname to avoid indexing problems on some players/filesystems
  def safe_filename_without_gcd
    @location[@playlist.gcd.length .. -1].gsub(/[^A-Za-z0-9\.\/,' -]/, "_")
  end
end
