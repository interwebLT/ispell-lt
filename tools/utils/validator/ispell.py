#!/usr/bin/env python
"""
Priemon�s kreiptis � ispell �odyn�.

$Id: ispell.py,v 1.1 2003/06/11 10:06:48 alga Exp $
"""
import os

def splitEntry(line):
    line = line.strip()
    index = line.find("#")
    if index >= 0:
        line = line[:index]
        line = line.strip()
    index = line.find("/")
    if index >= 0:
        word = line[:index]
        flags = line[index+1:]
        return word, flags
    return line, ""

def expand(line):
    """Gr��ina sur��iuot� s�ra�� �od�i�, � kuriuos i�siskleid�ia eilut�"""

    input, output = os.popen2("ispell -e")
    #import pdb; pdb.set_trace()
    input.write(line)
    input.flush()
    input.close()
    words = output.read()
    output.close()
    words = words.split()
    words.sort()
    return words
