#!/bin/sed -Ef
### md-to-html: Sed script that converts Markdown to HTML code
# s/◗//
/Discord/d
s/%0A/\n/g
s/^[-*] /● /
s/[<>]//g
s/\[ *([[:alnum:] \&\;\?!,\)\+]*.{0,10}[[:alnum:] \&\;\?!,\)\+]+) *\] *\( *([^ ]+) *\)/<a href='\2'>\1<\/a>/g
# **text** and **text**
s/\*\*([^*]+)\*\*/<strong>\1<\/strong>/g
s/__([^_]+)__/<strong>\1<\/strong>/g
# *text* and *text*
s/\*([^*]+)\*/<em>\1<\/em>/g
s/_([^_]+)_/<em>\1<\/em>/g
# ~~text~~
s/~~([^~]+)~~/<del>\1<\/del>/g
s/~([^~]+)~/<s>\1<\/s>/g
# `text`
s/`([^`]+)`/<code>\1<\/code>/g
