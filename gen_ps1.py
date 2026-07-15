import base64, os, sys

# We construct the PS1 line by line using only double-quoted Python strings.
# Dollar signs in PS are escaped as \x24 in Python double-quoted strings,
# or just written literally in the string since Python does not expand them.
# Single quotes in PS content are fine inside Python double-quoted strings.

L = []
def a(s): L.append(s)
a("param()")
a("$vaultRoot  = \"C:\\Users\\awt\\Sync\\Obsidian\"")
