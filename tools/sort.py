#!/usr/bin/env python
# -*- coding: iso-8859-13 -*-
#
# Autorius: Laimonas V�bra, 2010
#
"""
sort.py -- surikiuoja (pagal lokal�) failo arba STDIN eilutes/�od�ius.
Moka i�valyti komentarus, pa�alinti besikartojan�ias eilutes, "gudriai" 
rikiuoti, t.y. atsi�velgti � tam tikr� failo strukt�r� (kol kas moka 
rikiuoti u�komentuotuos �od�ius, ignoruojant komentar�)

Usage: 
	./sort.py [options] file > sorted
	cat file | sort.py [options] > sorted

Options:
	see usage()
"""

import os, sys
import fileinput
import getopt
from locale import setlocale, getdefaultlocale, LC_COLLATE, strxfrm


# sets modulis paseno ir nuo v2.6+ sistemoje (built-in) j� kei�ia
# set/frozenset tipai; importuojant pasenus� -- �sp�jama (warning).
if sys.version_info < (2, 6):
    from sets import Set


def _set(arg=''):
    if sys.version_info < (2, 6):
        return Set(arg)  
    else:
        return set(arg)



def usage():
	print \
"""
Usage: 
	sort.py [-h,--help] [-s,--strip] [-u,--unique] file|STDIN

Options:
	-h, --help      Display this help message;
        -c, --clean     Clean/strip all comments (#);
        -s, --smart     Smart sort (inc. commented words);
        -u, --unique    Remove duplicate lines.
"""



try:
	opts, rargs = getopt.getopt(sys.argv[1:], 
			"hcsu", ["help", "clean", "smart", "unique"])

except getopt.GetoptError:
	usage()
	sys.exit(2)               


unique_lines = 0
strip_comments = 0
smart_sort = 0


for opt, arg in opts:
	if opt in ("-h", "--help"):
            usage()                     
            sys.exit(2)


        if opt in ("-c", "--clean"):
            strip_comments = 1

        if opt in ("-s", "--smart"):
            smart_sort = 1

        if opt in ("-u", "--unique"):
            unique_lines = 1



# win lokal�s atpa�inimo/nustatymo problemos...
locale = getdefaultlocale()
if os.name is "nt":
	locale = "Lithuanian"

try:
	setlocale(LC_COLLATE, locale)
except:
	sys.stderr.write("Could not set locale\n")


def _tsmart(s):
	""" Smart (custom) transfrom; strxfrm() """
	# Ignoruojame komentaro simbol� ir rikiuojame pagal �od� u� jo
	if s.startswith("#"): s = s[1:]
	return strxfrm(s)
		


def sort(lines):
	words = []
	uset = _set()	    	

	for line in lines:
	        line = line.strip()

		if (smart_sort or strip_comments):
		        lwords = line.split("#")
			word1 = lwords[0].strip()
			if len(lwords) >= 2:
				word2 = lwords[1]  
			else: 
				word2 = None
		

			if not word1:
				if (smart_sort and word2):
					# XXX prielaida:
					# po komentaro tarpas; tai komentar� 
					# bloko (ar �iaip) komentaras, bet ne 
					# u�komentuotas _�odyno_ �odis.
					if word2.startswith((" ", "\t")):
						if strip_comments: continue

				else: continue				

			else: 
				if strip_comments: line = word1


                       
		if unique_lines:
			if line not in uset: 
				words.append(line)
			uset.add(line)
		else:
			words.append(line)			
	
	
	if smart_sort:
		words.sort(key=_tsmart)
	else:
		words.sort(key=strxfrm)
	

	for line in words: 
		print line



if __name__ == "__main__":
    sort(fileinput.input(rargs))
