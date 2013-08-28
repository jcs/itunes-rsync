#!/usr/bin/ruby
# $Id: itunes-rsync.rb,v 1.5 2009/01/27 09:11:14 jcs Exp $
#
# rsync the files of an itunes playlist with another directory, most likely a
# usb music device.
#
# creates symlinks in a scratch directory pointing to the real destination
# directory, then uses rsync to actually copy them out to the destination.
#
# requires the appscript gem
#
# Copyright (c) 2009, 2012 joshua stein <jcs@jcs.org>
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
  exit 1
end

puts "querying itunes for playlist \"#{playlist}\"..."

itunes = Appscript.app.by_name("iTunes", ITunesFix)
begin
  if !(itpl = itunes.playlists[playlist])
    raise "no such playlist with that name"
  end

  tracks = itpl.file_tracks.get.map{|t| t.location.get.path }
rescue => e
  puts "could not find playlist #{playlist.inspect}, exiting"
  exit 1
end

# figure out how much space we're going to take
bytes = 0
tracks.each{|t| bytes += File.size(t) }
mbytes = bytes.to_f / (1024 * 1024)

puts "found #{tracks.length} track#{tracks.length == 1 ? "" : "s"} with " +
  "size #{sprintf("%0.2fMb", mbytes)}"

# make sure the destination can take it
df_m = `df -m #{destdir}`.split("\n").last.split(" ")[1].to_i
if mbytes > df_m
  puts "error: #{destdir} has size of #{df_m}Mb, need #{mbytes.ceil}Mb to sync"
  exit 1
end

# figure out where all tracks are stored by checking for the greatest common
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

td = `mktemp -d /tmp/itunes-rsync.XXXXX`.strip

# link each track into the workspace
print "linking files under #{td}/... "
tracks.each do |t|
  shortpath = t[gcd.length .. t.length - 1]
  tmppath = "#{td}/#{shortpath}"

  # restrict pathnames to avoid indexing problems on some players/filesystems
  tmppath.gsub!(/[^A-Za-z0-9\.\/,' -]/, "_")

  if !Dir[File.dirname(tmppath)].any?
    system("mkdir", "-p", File.dirname(tmppath))
  end

  File.symlink(t, tmppath)
end

puts "done."

# times don't ever seem to match up, so only check size
puts "rsyncing to #{destdir}... "
system("rsync", "-Lrv", "--size-only", "--progress", "--delete",
  "#{td}/", destdir)

print "cleaning up... "
system("rm", "-rf", td)
puts "done."
