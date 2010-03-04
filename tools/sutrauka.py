#!/usr/bin/env python
# -*- coding: iso-8859-13 -*-
#
# Autorius: Albertas Agejevas, 2003
# Koregavo: Laimonas V�bra, 2010
#
"""
ispell-lt projekto/�odyno �rankis.
Suglaud�ia/sutraukia prie�d�linius veiksma�od�ius, pvz.: 
    pa|eina, nu|eina, at|eina, ... -> eina/bef...

o taip ir skirtingas tokio pa�io �od�io afikso �ymas, pvz.:
    dviratis/D, dviratis/B -> dviratis/DB 

�od�iai ir j� �ymos glaud�iamos tik suderinam� (kalbos dali�) 
grup�se. Dabar tai: veiksma�od�iai, b�dvard�iai ir lik�.  Taip 
padaryta tod�l, kad veiksma�od�iai gali tur�ti aib� prie�d�lini� 
�ym� ir kartu su kitos kalbos �ymomis gali generuoti daug 
neteising� form�, arba da�nos b�dvard�i� /N �ymos ne visuomet 
tinka daiktavard�iams (ir kt.), pvz.:

    jung�/D       (daiktavardis)
    jung�/Pef...  (b�t. k. l. veiksma�odis)

    jung�/DPef... generuot� neteisingas formas: 
        {prie�d�liai}{daikt. 'jung�' linksniai}

    baltaodis/BDN -> ne[be]baltaod�iui (daiktavardis) -- blogai,    
                  -> ne[be]baltaod�iam (b�dvardis)    -- gerai.

Naudojimas:
    ./sutrauka �odynas.txt > sutraukta.txt
    cat �odynas.txt | ./sutrauka > sutraukta.txt

"""
import os
import sys
import fileinput

from locale import setlocale, getdefaultlocale, LC_COLLATE, strxfrm

# sets modulis paseno ir nuo v2.6+ sistemoje (built-in) j� kei�ia
# set/frozenset tipai; importuojant pasenus� -- �sp�jama (warning).
if sys.version_info < (2, 6):
    from sets import Set


wcount = 0  # constringed words count
bcount = 0  # saved bytes count


def _stats(word, cflags, var=0):
    global wcount, bcount
    
    # Statistika (sutaupyta �od�i� ir vietos)... 
    #
    # Kiek sutaupoma vietos (bcount) suskliaud�iant �od�:
    # �od�io ilgis + bendr� �ym� kiekis + _papildomi_ (2 arba 1)
    # priklausomai nuo varianto:
    #   - kai �odis be afiks� -- sutaupoma: '/', '\n' (2)
    #   - kai [var]iantas > 0 -- prie�d�linis veiksma�odis ir
    #                            sutaupoma:      '\n' (1)
    #                            ('/' kei�ia prie�d�lio afikso �yma)
    #
    wcount += 1
    bcount += len(word) + len(cflags) + (2 if not (var and cflags) else 1)



def _set(arg=''):
    if sys.version_info < (2, 6):
        return Set(arg)  
    else:
        return set(arg)


def sutrauka(lines, outfile=sys.stdout, myspell=True):
    i = 0
    adjes = {}
    verbs = {}
    words = {}


    vflags = _set("TYEP")  # verb flags -- veiksma�od�i� gr. �ymos.
    aflags = _set("AB")    # adjective flags -- b�dvard�i� gr. �ymos.

    # Debug
    #f = open('./sutrauka.err', 'w')
    
    # win lokal�s atpa�inimo/nustatymo problemos...
    locale = getdefaultlocale()
    if os.name is "nt":
        locale = "Lithuanian"

    try:
        setlocale(LC_COLLATE, locale)
    except:
        sys.stderr.write("Could not set locale\n")


    sys.stderr.write("\n--- " + sys.argv[0] + ' ' + 
                     '-' * (60 - len(sys.argv[0]) - 5) + 
                     "\nReading ")        

    for line in lines:
        # Skaitymo progresas...
        if not lines.lineno() % 5000:
            sys.stderr.write(".")
            sys.stderr.flush()

        # Ignoruojamos tu��ios ir komentaro eilut�s.
        line = line.strip()
        line = line.split("#")[0]
        if not line:
            continue
        
        # Eilut� skeliama � �od� ir jo �ym� rinkin�.
        sp = line.split("/")
        word = sp[0]
        if len(sp) > 1:
            wflags = _set(sp[1])
        else:
            wflags = _set()
       
        # Veiksma�od�iai ir b�dvard�iai � atskirus dict.
        if vflags & wflags:
            d = verbs
        elif aflags & wflags:
            d = adjes
        else:
            d = words

        # �odis pridedamas � dict arba jei jau yra -- suliejamos �ymos
        if word not in d:
            d[word] = wflags
        else:
            swflags = d[word]  # stored word flags
           
            # Debug
            #f.write("Skliaud�iamas �odis '{0}':\n\t"
            #        "aff: {1}\n\taff: {2}\n".format(word, wflags, swflags))

            _stats(word, swflags & wflags)
            swflags.update(wflags)


    sys.stderr.write("\nProcessing ")

    # Suskliaud�iami prie�d�liniai veiksma�od�iai
    d = verbs
    for word in d.keys():
        # Apdorojimo progresas...
        i += 1
        if not (i % 5000):
            sys.stderr.write(".")
            sys.stderr.flush()
       
        # �odis (jau) gal�jo b�ti pa�alintas i� words dict...
        if word not in d:
            continue

        # �od�io afiks� �ym� rinkinys.
        wflags = d[word]
                
        # Kiekvienam �odyno �od�iui derinami/tikrinami visi prie�d�liai.
        for pflag, pref in prefixes:

            if word.startswith(pref):

                # Jei pref sangr��inis prie�d�lis, tai �odis atmetus paprast�j� 
                # (nesangr��in�) prie�d�l�, pvz.: i�{si}|urbia -> siurbia.
                # Kai toks �odis yra �odyne, tai situacija netriviali, nes 
                # �odyne yra trys �od�io formos: su prie�d�liu, be prie�d�lio 
                # ir be sangr��inio prie�d�lio.  Tampa nebeai�ku kok� prie�d�l� 
                # (sangr��in� ar ne) ir kokiam �od�iui pritaikyti; toki� 
                # �od�i� savaime suskliausti ne�manoma, pvz.:
                #     i�{si}|urbia, siurbia, urbia (i�|siurbia ar i�si|urbia?)
		#     at{si}|joja, sijoja, joja;   (at|sijoja ar atsi|joja?)
                #
                # (word without reflexive prefix part)
                #
                wrpword = word[len(pref)-2:] if pref.endswith("si") else None
    
                # �odis be prie�d�lio, pvz.: per|�oko -> �oko.
                # (word without prefix) 
                wpword = word[len(pref):]                
                
                if wpword in d:
                    wpflags = d[wpword]
   
                    if wrpword not in words:
                        # and wflags.issubset(wpflags))
                        #
                        # Skliaud�iant prie�d�linius veiksma�od�ius d�l /X /N 
                        # prie�d�lini� dalely�i� (ispell apribojimo jas 
                        # pridedant/jungiant) prarandamos kelios prie�d�linio 
                        # veiksma�od�io formos, pvz:
                        #   pavartyti/X  >  te|pa|vartyti, tebe|pa|vartyti, 
                        #                   be|pa|vartyti, ...
                        # vs
                        #    vartyti/Xf  >  tevartyti, tebevartyti, 
                        #                   bevartyti, ...
                        #
                        # Tod�l skliaud�iant neb�tina tikrinti ar sutampa �od�i�
                        # (prie�d�linio ir �akninio) �ym� aib�s; praradimas vyksta, 
                        # net jei jos sutampa, o netikrinant, t.y. susitaikius su
                        # ir taip vykstan�iu prie�d�lini� darini�/form�: 
                        #  [tebe, be, te, nebe] {prie�d�lis} �odis 
                        #
                        # praradimu, �odyn� suglaudinamas dar vir� 50 kB.
                        #
                        # ARBA atvirk��iai -- siekiant, kad neb�t� praradim�, kaip 
                        # tik nereik�t� toki� �od�i� (jei prie�d�linis �odis turi 
                        # /X, /N �ymas) glaudinti.
                        
                        # Debug
                        #    f.write("\nNeskliaud�iamas �odis '{0}|{1}', nes nesiderina afiksai:"
                        #            "\n\t(su prie�d.) aff: {2}"
                        #            "\n\t(be prie�d.) aff: {3}\n".format(pref, wpword, wflags, wpflags))
                        
                        _stats(word, wflags & wpflags, 1)

                        # Suliejamos afiks� �ymos ir pridedama prie�d�lio �yma.
                        wpflags.update(wflags)
                        wpflags.add(pflag)
                 
                        # �odis sukliaustas (prie �akninio �od�io sulietos 
                        # �ymos, prid�ta prie�d�lio afikso �yma).  Pa�aliname 
                        # prie�d�lin� �od� i� 'verbs' dict ir baigiame 
                        # prie�d�li� cikl�, nes prie�d�liai unikal�s ir �od�io
                        # prad�ia nebegali sutapti su jokiu kitu prie�d�liu.
                        del d[word]
                        break

    sys.stderr.write(" done.\nWords constringed: {0}, "
                     "bytes saved: {1}.\n".format(wcount, bcount) + 
                     '-' * 60 + '\n')

    res = []
    for word, flags in words.items() + verbs.items() + adjes.items():
        if flags:
            f = list(flags)
            f.sort()
            end = "/" + "".join(f)
        else:
            end = ""

        res.append((strxfrm(word), word + end))

    res.sort()

    # myspell'o �odyno prad�ioje -- �od�i� kiekis.
    if myspell:
        print >> outfile, len(res)

    for word in res:
        print >> outfile, word[1]

prefixes = (
    ("a", "ap"),
    ("a", "api"),
    ("b", "at"),
    ("b", "ati"),
    ("c", "�"),
    ("d", "i�"),
    ("e", "nu"),
    ("f", "pa"),
    ("g", "par"),
    ("h", "per"),
    ("i", "pra"),
    ("j", "pri"),
    ("k", "su"),
    ("l", "u�"),
    ("m", "apsi"),
    ("n", "atsi"),
    ("o", "�si"),
    ("p", "i�si"),
    ("q", "nusi"),
    ("r", "pasi"),
    ("s", "parsi"),
    ("t", "persi"),
    ("u", "prasi"),
    ("v", "prisi"),
    ("w", "susi"),
    ("x", "u�si"),
    )


if __name__ == "__main__":
    sutrauka(fileinput.input(), myspell=False)
