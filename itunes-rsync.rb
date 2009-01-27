#!/usr/bin/ruby
# $Id: itunes-rsync.rb,v 1.1 2009/01/27 08:49:12 jcs Exp $
#
# rsync an itunes playlist with another directory, most likely a usb music
# device
#
# requires the rubyosa gem ("sudo gem install rubyosa")
#
# Copyright (c) 2009 joshua stein <jcs@jcs.org>
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
require "rbosa"

if !ARGV[1]
  puts "usage: #{$0} <itunes playlist> <destination directory>"
  exit
end

playlist = ARGV[0]

if Dir[ARGV[1]].any?
  destdir = ARGV[1]

  if !destdir.match(/\/$/)
    destdir += "/"
  end
else
  puts "error: directory \"#{destdir}\" does not exist, exiting"
  exit
end

print "querying itunes for playlist \"#{playlist}\"... "

# disable a stupid xml deprecation warning
$VERBOSE = nil
itunes = OSA.app("iTunes")

itpl = itunes.sources.select{|s| s.name == "Library" }.first.
  user_playlists.select{|p| p.name.downcase == playlist.downcase }.first

if !itpl
  puts "could not locate, exiting"
  exit
end

tracks = itpl.file_tracks.map{|t| t.location }

puts "found #{tracks.length} track#{tracks.length == 1 ? '' : 's'}."

# figure out where all of them are stored by checking for the greatest common
# directory of every track
gcd = ""
(1 .. tracks.map{|t| t.length }.max).each do |s|
  piece = tracks[0][0 .. s - 1]

  ok = true
  tracks.each do |t|
    if t[0 .. s - 1] != piece
      ok = false
    end
  end

  if ok
    gcd = piece
  else
    break
  end
end

# setup work dir
td = `mktemp -d /tmp/itunesrsync.XXXXX`.strip

# mirror directory structure and create symlinks
print "linking files under #{td}/... "

tracks.each do |t|
  shortpath = t[gcd.length .. t.length - 1]
  tmppath = "#{td}/#{shortpath}"

  if !Dir[File.dirname(tmppath)].any?
    system("mkdir", "-p", File.dirname(tmppath))
  end

  system("ln", "-s", t, tmppath)
end

puts "done."

# times don't ever seem to match up, so only check size
puts "rsyncing to #{destdir}... "
system("rsync", "-Lrv", "--size-only", "--delete", "#{td}/", destdir)

print "cleaning up... "
system("rm", "-rf", td)
puts "done."
