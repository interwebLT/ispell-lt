#!/usr/bin/env python3
# -*- coding: iso-8859-13 -*-
'''
$Id: spell.py,v 1.4 2003/11/24 23:51:16 alga Exp $

Paleidimas:

  python3 spell.py [-m] [infile]

     -m     -- nurodo, kad �od�ius reikia d�ti � lietuviu.zodziai ir
               lietuviu.veiksmazodziai, o ne lietuviu.privatus

     infile -- failas, i� kurio skaityti po vien� �od�ius (u�uot
               skai�ius i� klaviat�ros)
'''

import sys
import os
from popen2 import popen2

def entry(prompt, default=None):
    """Input"""
    if default:
        prompt = "%s [%s]> " % (prompt, default)
    result = raw_input(prompt)
    result.strip()
    if not result:
        return default
    else:
        return result

def binary(prompt, default=False):
    """Klausimas, � kur� atsakymas yra taip arba ne"""
    default_str = default and "taip" or "ne"
    result = raw_input("%s [%s]> " % (prompt, default_str))
    result.strip()
    if not result:
        return default
    else:
        return result[0] in "TtYy"

def multi(prompt, *args):
    """Multiple choice.
    """
    prompt = "%s (%s)> " % (prompt,
                            ", ".join(["[%s]%s" % (choice[0], choice[1:])
                                       for choice in args]))
    result = raw_input(prompt)
    result.strip()
    if result:
        return result[0]

def minkst(zod):
    """Jei zod baigiasi d arba t, pakei�ia d� arba �

    �od-is --> �od�-io
    kirt-is --> kir�-io
    sald-us --> sald�-iausias
    """
    if zod[-1] == 't':
        return zod[:-1] + "�"
    elif zod[-1] == 'd':
        return zod[:-1] + "d�"
    else:
        return zod

def daiktavardis(zodis):
    if zodis.endswith("is"):
        if binary("%s, %sio? " % (zodis, zodis[:-2])):
            return "%s/D" % zodis
        elif binary("Ar tai vyri�kos gimin�s daiktavardis?"):
            return  "%s/V" % zodis
        elif binary("%s, %s�" % (zodis, zodis[:-2])):
            return  "%s/MK" % zodis
        else:
            print "Vadinasi, %s, %si�" % (zodis, minkst(zodis[:-2]))
            return  "%s/MI" % zodis
    elif zodis.endswith("uo"):
        if binary("Ar tai vyri�kos gimin�s daiktavardis?"):
            return  "%s/V" % zodis
        else:
            return  "%s/M" % zodis
    else:
        return "%s/D" % zodis


priesdeliai = {
    "a": "ap",
    "b": "at",
    "c": "�",
    "d": "i�",
    "e": "nu",
    "f": "pa",
    "g": "par",
    "h": "per",
    "i": "pra",
    "j": "pri",
    "k": "su",
    "l": "u�",
    "m": "apsi",
    "n": "atsi",
    "o": "�si",
    "p": "i�si",
    "q": "nusi",
    "r": "pasi",
    "s": "parsi",
    "t": "persi",
    "u": "prasi",
    "v": "prisi",
    "w": "susi",
    "x": "u�si",
    }

def veiksmazodis(inf, es=None, but=None):
    print "Bendratis: %s" % inf
    if es is None:
        es = entry("Esamasis laikas (k� daro?)> ")
    if but is None:
        but = entry("B�tasis kartinis (k� dar�?)> ")

    inf_flag = "T"
    es_flag = "E"

    # Gyti, gija, gijo, gis
    if inf[-3] == "y" and es[-3] == "y" and but[-3] == "i":
        inf_flag = "U"

    # P�ti, p�va, puvo, pus
    if inf[-3] == "�" and es[-3] == "�" and but[-3] == "u":
        inf_flag = "U"

    if inf.endswith("yti"):
        but_flag = "Y"
    else:
        but_flag = "P"

    if binary("%ss, %ssi, %ssi?" % (inf, es, but)):
        sangraza = "SX"
    else:
        sangraza = "NX"

    flagai = []
    for flag, priesdelis in priesdeliai.items():
        if inf[0] in "pb":
            fmt = "%si%s?"
        else:
            fmt = "%s%s?"
        if binary(fmt % (priesdelis, inf)):
            flagai.append(flag)
    flagai = "".join(flagai)

    if sangraza == "SX":
        return "\n".join(("%s/%s%s%s" % (inf, inf_flag, sangraza, flagai),
                          "%s/%s%s%s" % (es, es_flag, sangraza, flagai),
                          "%s/%s%s%s" % (but, but_flag, sangraza, flagai),
                          "%ss/%s" % (inf, inf_flag),
                          "%ssi/%s" % (es, es_flag),
                          "%ssi/%s" % (but, but_flag),
                          ))
    else:
        return "\n".join(("%s/%s%s%s" % (inf, inf_flag, sangraza, flagai),
                          "%s/%s%s%s" % (es, es_flag, sangraza, flagai),
                          "%s/%s%s%s" % (but, but_flag, sangraza, flagai),
                          ))

def kokybinis(zodis):
    """Paklausia, ar b�dvardis kokybinis, ir gr��ina "Q" arba "". """

    if binary("Ar jis yra kokybinis (%s, %sesnis, %siausias, )?" %
              (zodis, zodis[:-2], minkst(zodis[:-2]))):
        return "Q"
    else:
        return ""

def budvardis(zodis):
    if not zodis.endswith("is") or zodis in ('didis', 'didelis'):
        return "%s/ANQ" % zodis
    else:
        return "%s/BN" % zodis

def prideti(failas, zodis):
    """Prideda �od� � fail�"""
    f = open(failas, "a")
    f.write(zodis)
    f.write("\n")
    f.close()

def patikrinti(zodis):
    child_out, child_in = popen2("ispell -d ./lietuviu -l")
    child_in.write(zodis)
    child_in.close()
    rez = child_out.read()
    return (len(rez) == 0)

def ispell_yra():
    out = os.popen("ispell -v")
    return out.close() is None

def gauti_zodi(file=None):
    if file is None:
        return entry("�veskite pradin� �od�io form�> ")
    while 1:
        line = file.readline()
        line = line.strip()
        zodis = line.split("/")[0]
        if not zodis:
            continue
        if patikrinti(zodis):
            print "*** %s jau yra �odyne" % zodis
        else:
            break
    print ">>> %s " % line
    pataisymas = entry("[%s] >" % zodis)
    if pataisymas:
        zodis = pataisymas
    return zodis


def find_ispell_home():
    envpath = os.getenv("ISPELLLT")
    if envpath:
        os.chdir(envpath)
        return
    elif os.path.exists("lietuviu.dict"):
        return
    elif os.path.exists(os.path.join("..", "ispell-lt", "lietuviu.dict")):
        os.chdir(os.path.join("..", "ispell-lt"))
        return
    else:
        print "Nerandu ispell direktorijos -- " \
              "nustatykite ISPELLLT aplinkos kintam�j� � direktorij�,\n" \
              "kurioje yra lietuviu.dict ir kiti ispell failai."
        sys.exit(1)


def main(*args):
    infile = None
    maintainer_mode = False
    privatus = None
    turim_ispell = ispell_yra()

    find_ispell_home()

    for arg in args[1:]:
        if arg == '-m':
            maintainer_mode = True
        else:
            infile = open(arg)
            break
    try:
        if os.getenv("HOME"):
            privatus = os.path.join(os.getenv("HOME"), '.ispell_lietuviu')
        while True:
            zodis = gauti_zodi(infile)
            if turim_ispell and patikrinti(zodis):
                print "Beje, '%s' jau yra �odyne." % zodis
            dalis = multi("Kokia tai kalbos dalis?\n",
                          "veiksma�odis", "daiktavardis",
                          "budvardis", "nekaitoma")
            if maintainer_mode:
                dalys = { "d": (daiktavardis, "lietuviu.zodziai"),
                          "v": (veiksmazodis,  "lietuviu.veiksmazodziai"),
                          "b": (budvardis, "lietuviu.zodziai"),
                          "n": (lambda x: x, "lietuviu.zodziai"),
                          }
            else:
                dalys = { "d": (daiktavardis, "lietuviu.privatus"),
                          "v": (veiksmazodis,  "lietuviu.privatus"),
                          "b": (budvardis, "lietuviu.privatus"),
                          "n": (lambda x: x, "lietuviu.privatus"),
                          }
            try:
                dorokle, failas = dalys[dalis]
                irasas = dorokle(zodis)
                print "Dedam � %s:" % failas
                print irasas
                prideti(failas, irasas)
                if privatus:
                    prideti(privatus, irasas)
                print "Prid�ta."
            except KeyError:
                print "Kas kas?"
    except (EOFError, KeyboardInterrupt):
        print
        return

if __name__ == "__main__":
    main(*sys.argv)
