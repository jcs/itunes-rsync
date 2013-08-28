rsync the files of an itunes playlist with another directory, most likely a usb
music device.

creates symlinks in a scratch directory pointing to the real destination
directory, then uses rsync to actually copy them out to the destination.

requires the `appscript` gem.

usage: `ruby itunes-rsync.rb "ipod (auto)" /Volumes/music/`
