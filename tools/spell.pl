#!/usr/bin/perl -w
# spell.pl 0.5.0
# 
# Skriptas(imho jau i�augo i� "skriptuko" dyd�io bei funkcionalumo) naujiems 
# lietuvi�kiems ispell �odynams sudarin�ti. Skaito �od�ius, ir jeigu neapibr��ti 
# jokie flagai, i�siai�kina, koki� reikia, bei i�saugo �od� /~ esan�iuose �odynuose
# i� kuri�, v�liau, kompiliuojamas pagrindinis ispell �odynas.
#
# Vartojimas:
# spell.pl                       # skaito �od�ius i� klaviat�ros
# spell.pl �odynas               # skaito i� failo �odynas
#
# Para�� Laimonas V�bra <l.v@centras.lt> stipriai patobulin�s skript�, kur�
# para�� Gediminas Paulauskas <menesis@delfi.lt>, patobulin�s skriptus i�
# Alberto Agejevo <alga@uosis.mif.vu.lt> bei Mariaus Gedmino <mgedmin@delfi.lt>. :)
# 
# TODO:
# * daugiau intelekto atsp�jant �od�i� formas
# * parametrais nurodomos �vesties/i�vesties bylos 
# # ispell �odyno kompiliavimas
# # UI pagerinimas, galb�t .conf file'iukas
# # �od�i� automatinio patikrinimo/kaupimo sistema susieta su http://doneaitis.vdu.lt resursais
# # yra min�i�, sumanym�..
# #
# #
#             api ati
#             ap  at  � i� nu pa par per pra pri su u�
# be nieko     a   b  c  d  e  f  g   h   i   j   k  l
# su sangr��a  m   n  o	 p  q  r  s   t   u   v   w  x
$SIG{INT} = \&sub_exit;  
$SIG{TERM} = \&sub_exit;
$SIG{KILL} = \&sub_exit;

%prefix = (
	   c => '�',     d => 'i�',	e => 'nu',
	   f => 'pa',    g => 'par',    h => 'per',
	   i => 'pra',	 j => 'pri',	k => 'su',
	   l => 'u�',	 m => 'apsi',	n => 'atsi',
	   o => '�si',	 p => 'i�si',	q => 'nusi',
	   r => 'pasi',	 s => 'parsi',	t => 'persi',
	   u => 'prasi', v => 'prisi',	w => 'susi',
	   x => 'u�si'
);
# filename hash
%fn_h = (
	 1 => 'lietuviu.daiktavardziai', 2 => 'lietuviu.tarpt.daiktavardziai', 3 => 'lietuviu.vardai', 
	 4 => 'lietuviu.veiksmazodziai', 5 => 'lietuviu.tarpt.veiksmazodziai', 
	 6 => 'lietuviu.budvardziai', 7 => 'lietuviu.tarpt.budvardziai', 
	 8 => 'lietuviu.nekaitomi', 9 => 'lietuviu.ivairus', 10 => 'lietuviu.jargon'
);
# file handle hash
%fh_h = (
	 1 => 'DAIKT', 2 => 'TARPT_DAIKT', 3 => 'VARDAI', 
	 4 => 'VEIKS', 5 => 'TARPT_VEIKS',
	 6 => 'BUDV', 7 => 'TARPT_BUDV',
	 8 => 'NEKAIT', 9 => 'IVAIR', 10 => 'JARGON'
);

$versija = "spell.pl 0.5.0, para�� Laimonas V�bra <l.v\@centras.lt>, 2002, Vilnius.";
# Escape sekos spalvotam ra�ymui
$G="\e[1;33m"; # geltona
#$Z="\e[1;32m"; # �alia
$R="\e[1;31m"; # raudona
#$M="\e[0;34m"; # m�lyna
$B="\e[1;37m"; # balta
$Y="\e[1;36m"; # �ydra
#$V="\e[0;35m"; # violetin�
$d="\e[0;39m";  # pagrindin�(default)

#  @bkl_veiks_daikt_pries
#B�tojo kartinio laiko(bkl) form� �aknies bals� da�niausiai(su retomis i�imtimis) turi �i� priesag� veiksma�odiniai daiktavard�iai
#gyn-(imas) (: gyn�) , myn-(ikas) (: myn�), ...
@bkl_veiks_daikt_pries=('imas','ikas','�jas','�ja','yba','ykla','inys','iklis', 'oklis', '�nas','�n�', '�lis','�l�', 'ena', '�sis');

# @veiks_bendr_daikt_pries
# Bendraties �akn� turi �i� priesag� daiktavard�iai
# -tuvas, -tuv� : vytuvas( :vyti), trintuvas (:trinti), durtuvas (: durti)
@veiks_bendr_daikt_pries=('tuvas','tuv�','tukas','tis','tas','tyn�','klas','kl�','klys');

local $found_u = 0; # ar �odis buvo rastas vartotojo ( (u)ser ) �odyne
local $found_i = 0; # ar �odis buvo rastas pagrindiniame, ispell'o ( (i)spell ) �odyne
local $flags;
local ($opt_b, $opt_B,  # force  black & white
       $opt_v, $opt_V,  # print version
       $opt_h, $opt_H,  # print usage(--help)
       $opt_p, $opt_P,  # PATH (jei �odynai yra ne /~ direktorijoje)
       $opt_f, $opt_F   # Tekstinis �od�i� failas
);


# Komandin�s eilut�s argument� tikrinimas
use Getopt::Std;

if( !getopts('bBvVhHp:P:f:F:') || @ARGV ) { 
    print "�vyko klaida - neteisingai nurodyti argumentai.\nPer�i�r�kite ar programa buvo i�kviesta teisingai?\n";
    exit;
}
else {
    if ($opt_b || $opt_B) {
	# Force Black & White. Sutinku, kad spalvos gali r��ti ak� ar �kyr�ti. TODO: custom colors
	$d = $Y = $R = $G = $B = '';
    }
    if($opt_v || $opt_V) { 
	print "$versija\n"; 
	exit;
    }
    if($opt_h || $opt_H) {
	&usage();
	exit;
    }
    
}

$pskirt = "$B"."====================$d\n"; # �od�io �vedimo (p)abaigos skiriamoji eilut�

&atidaryti_zodynus();

print "\n-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n";
print "Programa, nustatanti nauj� �od�i� afiksus ir ra�anti �od�ius � �odynus. \n";
print "V�liau i� �i� �odyn� yra kompiliuojamas lietuvi� kalbos $G"."ispell$d �odynas.\n";
print "    -$B Ctrl+D$d bet kada gr��ta � programos prad�i�.\n";
print "    -$B Ctrl+C$d bet kada nutraukia programos vykdym�.\n";
print "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n";

$ARGV = '-'; # i�ankstinis nustatymas � STDIN

if($opt_f || $opt_F) { 
    $_ = defined($opt_f) ? $opt_f : $opt_F; 
    if(-e && -T) { $ARGV = $_; }
    else {
	print "$R"."Klaida$d, n�ra tokio failo: $B$_$d, arba jis n�ra tekstinis.\nBlogas programos rakto -(f|F) argumentas.\n"; 
	print "Nagrin�siu j�s� �vedamus �od�ius..\n";
    }
}

$KLAUSTI = $ARGV eq '-';
open (BYLA, $ARGV) or warn "Negaliu atidaryti $ARGV: $!\n";

# Pradedam..
&main();

sub main() {
    my $msg;
    my $main_msg = "\n�veskite �od� ($G\^D$B baigti$d\, $G"."?$B pagalba$d\): $B";
    print  $main_msg if $KLAUSTI;
    
    while ($word = <BYLA>) {{
	if ($word =~ /^[\s\#]+/) { next; } 
	elsif($word =~ /.\/./) { # komentarai, tu��ios eilut�s bei �od�iai su flag'ais
	    chomp($word);
	    print "$word - jau turi afiksus.\n";
	    next;
	}

	chomp $word;
	print "$B$word$d\n";
	print "$d";
	if (!legal ($word)) { next; }  
	$flags = '';
	
	if ($word =~ /\?/) { pagalba(); next; }
	elsif ($word =~ /q/i) { sub_exit(); }
	
	$msg = "Tai $G"."d$d"."aiktavardis, $G"."v$d"."eiksma�odis, $G"."b$d"."�dvardis ar $G"."n$d"."ekaitomas �odis? ($G"."d$d\/$G"."v$d\/$G"."b$d\/$G"."n$d)";
	do  {
	    if(!ivesti_zodi($msg, 'n')) { next; }
	} until (/^[bdnvq\?]$/i);
	
	if    (/v/i) { veiksmazodis($word); }
	elsif (/d/i) { daiktavardis($word); }
	elsif (/b/i) { budvardis($word); }
	elsif (/n/i) { nekaitomas($word); }
	
	if(($found_u || $found_i) && $ARGV ne '-') { print "Nor�dami t�sti paspauskite $B\"Enter\"$d klavi��..."; $_ = <STDIN>; }
    
    }
    print $main_msg if $KLAUSTI;
    }
}  

sub veiksmazodis {
    my ($bend, $es, $but);
    my ($msg, $ats);
    
    print "$Y"."=== Veiksma�odis ===\n$B$word$d\n";
    $msg = "�veskite veiksma�od�io bendrat�($G"."k� daryti$d\/$G"."veikti?$d\)";
    do {
	if(! ($bend = ivesti_zodi($msg, ($word =~/.*tis?$/i) ? $word : '' )) ) { return; }
	elsif(!($bend =~ /.*tis?$/i)) { print "\n$R"."D�mesio$d\, veiksma�od�io bendratis turi baigtis gal�ne \'$G"."-ti(s)$d\' !\n"; }
    }until ($bend =~/.*tis?$/i);
    
    $msg =  "�veskite veiksma�od�io esam�j� laik�($G"."k� daro$d\/$G"."veikia?$d\)";
    if(! ($es = ivesti_zodi($msg, ($word =~/.*(a|[^t]i)$/i) ? $word : '' )) ) { return; };
    
    $msg = "�veskite veiksma�od�io b�t�j� kartin� laik� ($G"."k� dar�$d\/$G"."veik�?$d\)";
    if(! ($but = ivesti_zodi($msg, ($word =~/.*�$/i) ? $word : '')) ) { return; } 

    my %v_h = (1 => $bend, 2 => $es, 3 => $but); # pagrindini� (v)eiksma�od�io form� (h)ash
    my %vr_h = (1 => 0, 2 => 0, 3 => 0); # (v)eiksma�od�io forma (r)asta hash
    
    foreach $i (1,2,3) {
	&paieska_zodynuose($v_h{$i}, 2);  
	if($found_i || $found_u) { $vr_h{$i} = 1; }
    }
    if($found_i) {
	if($vr_h{1} && $vr_h{2} && $vr_h{3}) { return; } 
	else {
	    print "\n\nJ�s� �vest� veiksma�od�i�:\n";
	    foreach $i (1,2,3) { 
		if(!$vr_h{$i}) {  print "$B$v_h{$i}$d\n"; }
	    }
	    print "$R"."n�ra$d pagrindiniame ispell �odyne.\n\n";
	    print "Labai tik�tina, kad �ie, j�s� �vesti, veiksma�od�iai yra neteisingi, o\npagrindiniame �odyne yra saugomos teisingos veiksma�od�io formos(bendratis,\nesamasis bei b�tasis kartinis laikai).\n\n";
	    print "$B"."Kitavertus$d - neatmetama galimyb�, kad pagrindiniame ispell �odyne yra klaida.\n";
	    print "Jei manote, kad tai yra �odyno klaida -  b�kite malon�s, $B"."prane�kite$d\napie tai �odyno baz�s koordinatoriui.\n";
	}	
    }
    elsif($found_u) {
	# TODO :
	return;
    }
    if(!veiks_tikrinimas(\$bend, \$es, \$but)) { return; }
    foreach $i (keys (%prefix), 'a[pt]', 'a[pt]i') {
        $prefix = ($i =~ /^a\[/) ? $i : $prefix{$i};
        next unless ($bend =~ /^$prefix(.*)/); 
        local $sb = $1;
        next unless ($es =~ /^$prefix(.*)/); 
        local $se = $1;
        next unless ($but =~ /^$prefix(.*)/); 
        local $su = $1;
	$msg = "$R"."D�mesio$d\, gali b�ti, kad j�s� �vestas veiksma�od�is turi trumpesn�(be prie�d�li�)\npamatin� form�)\nAr teisinga: $sb, $se, $su?";
	$ats = taip_ne ($msg, "t");
	if(!$ats) {  return; }
	elsif($ats == 1) {   
	    print "Toliau nagrin�sim veiksma�od�ius: $sb, $se, $su\n";
	    $bend = $sb; $es = $se; $but = $su;
	    return;
	}
    }
    if (!append_flags("${bend}s, ${es}si, ${but}si?", 't', 'SX', 'NX')) { return; }
    
    $pref = ($bend =~ /^[bp]/i) ? 'api' : 'ap';
    if (!append_flags("$pref$bend, $pref$es, $pref$but?", 't', 'a')) { return; }
    
    $pref = ($bend =~ /^[dt]/i) ? 'ati' : 'at';
    if (!append_flags("$pref$bend, $pref$es, $pref$but?", 't', 'b')) {  return; }
    
    foreach $i (sort keys %prefix) {
        $pref = $prefix{$i};
        if (!append_flags("$pref$bend, $pref$es, $pref$but?", 't', "$i")) {  return; }
    }

    if ($bend =~ /[�y]ti$/i and  $es =~ /[�y].a$/i and $but =~ /[ui].o$/i) {
        $bf = "U";
    } else {
        $bf = "T";
    }

    $word = "$bend/$bf$flags\n";
    $word .= "$es/E$flags\n";
    if ($bend =~ /yti$/i){
	$word .= "but/Y$flags\n";
    } else {
	$word .= "$but/P$flags\n";
    }
    if ($flags =~ /S/) {
        $word .= "${bend}s/$bf\n";
        $word .= "${es}si/E\n";
        if ($bend =~ /yti$/i){
            $word .= "${but}si/Y";
        } else {
    	    $word .= "${but}si/P";
        }
    }
    print $pskirt;
    print "$word\n";
    irasyti_izodyna(2, $word);
    
}  # veiksma�od�io pabaiga

sub daiktavardis() {
    my $word = shift;
    my $msg;
    my $ats;
    print "\n=== $Y"."Daiktavardis$d ===\n$B$word$d\n";
    $msg = "�veskite vardininko laipsn� ($G"."kas?$d\)";
    do {
	if (! ($word = ivesti_zodi($msg, $word)) ) { return; }
    	elsif($word =~ /.*[^a�ios]$/i) { print "\n$R"."D�mesio$d\, daiktavard�io vardininko laipsnis turi baigtis raid�mis \'$G"."a,�,i,o,s$d\' !\n"; }
    } until( $word =~ /.*[a�ios]$/i );    

    &paieska_zodynuose($word, 1);
    if($found_i) { return; }
    elsif($found_u)  { return; }  # TODO 

    # Patikrinimas ar teisingai ra�omi veiksma�odini� daiktavard�i� �aknies balsiai #
    my $pries_id = 0;
    foreach (@bkl_veiks_daikt_pries) {
	if ($word =~ /.*$_$/i) { 
	    $pries_id = 1;
	    last;
	}
    }
    foreach (@veiks_bendr_daikt_pries) {
	if ($word =~ /.*$_$/i) { 
	    $pries_id = 2;
	    last;
	}
    }
    if ($pries_id && !daikt_teisingas_balsis($word, $pries_id)) {  return; }
    ##
		
    if ($word !~ /(.*)(is|uo)$/i) {
        $flags = 'D'
    } else {
        my ($sak, $gal) = ($1, $2);
	$sak =~ s/t$/�/;
    	$sak =~ s/d$/d�/;
	$ats = taip_ne('Ar �odis yra vyri�kos gimin�s?', 't');
	if(!$ats) {  return; }
       	if ($gal =~ /is/i && $ats == 1) {
	    # pana�u, kad visi vyri�kos gim. daiktavard�iai su gal�ne *.is  vns. kilmininko laipsnyje turi galun� *.io, tod�l klausimas(�r. �emiau) yra nereikalingas
	    # taip_ne ("Ar vienaskaitos kilmininko($G"."ko?$d\) linksnis yra \'$B${sak}io$d\'\?", "t")) {
	    $flags = 'D'
    	} else {
            $flags = ($ats == 1) ? 'V' : 'M';
            $msg = "Ar gal�n� mink�ta - daugiskaitos kilminiko($G"."ko?$d\) laipsnis yra \'$B${sak}i�$d\'?";
	    if (!append_flags($msg, 't', 'I', 'K')) {  return; }
    	}
    }
    if(!append_flags("Ar yra toks daiktas ne$word?", 'n', 'N')) {  return; }
    $word = "$word/$flags";
    print $pskirt;
    print "$word\n";
    irasyti_izodyna(1, $word);
}  # daiktavard�io pabaiga

sub budvardis {
    my ($kokyb, $ivardz);
    my $msg;
    my $ats;

    $word = $_[0];
    print "\n==== $Y"." B�dvardis$d =====\n$B$word$d\n";
    $msg = "�veskite vardininko laipsn� ($G"."kas?$d\)";  
    do {
	if (! ($word = ivesti_zodi($msg, $word)) ) {  return; }
	if($word =~ /.*[^s]$/i) { print "\n$R"."D�mesio$d\, b�dvard�io vardininko laipsnis turi baigtis raide \'$G"."s$d\' !\n"; }
    } until( $word =~ /.*s$/i );    

    &paieska_zodynuose($word, 3);
    if($found_i) { return; }
    elsif ($found_u) { return; } # TODO

    $word =~ /(.*)(.)s$/i;
    $kokyb = $2 ne 'i';
    $msg = "Ar tai kokybinis b�dvardis (kaip $1$2; ${word}is; turi laipsnius?)";
    if (! ($ats = append_flags($msg, 't', 'AQ')) ) {  return; }
    elsif($ats == 2) {
        my ($sak, $gal) = ($1, $2);
        $sak =~ s/t$/�/;
	$sak =~ s/d$/d�/;
        if(!append_flags("Ar tai santykinis b�dvardis (kokiems - ${sak}iams)?", 't', 'B', 'A')) {  return; } 
    }
    
    if(!append_flags("Ar gali b�ti ne$word?", 'n', 'N')) {  return; }
    $word = "$word/$flags";
    print $pskirt;
    print  "$word\n";
    irasyti_izodyna(3, "$word");
}  # b�dvard�io pabaiga


sub nekaitomas {

    $word = $_[0];
    print "\n==== $Y"." Nekaitomas$d =====\n$B$word$d\n";
    &paieska_zodynuose($word, 4);
    if($found_i) { return; }
    elsif ($found_u) { return; } # TODO

    irasyti_izodyna(4, "$word");
}  # nekaitomas pabaiga

sub legal {
    # Funkcija, kuri tikrina �vedam� �od�i� "legalum�". Mano manymu, tai �iek tiek padeda i�vengti klaid� ir sutaupyti laiko(pvz: v�lai pasteb�jus, kad klaidingai 
    # �vestas �odis, reikia i� naujo prad�ti proced�r�). 
    # Kitavertus, mano "u�programuotas legalumas" (besikartojantys, sulip� priebalsiai(pvz.: ' kk','��' ir t.t.), daugiau kaip trys  priebalsiai esantys greta
    # (pvz. : '.*nd�k.*'), gali b�ti klaidingas. Jei pasteb�site klaidas - prane�kite <l.v@centras.lt>

    if ($word =~/^[^?q]$|.*([b,c,�,d,f-h,j-n,p-t,�,v,z,�,�,�,�,�,�,�])\1+.*|.*[0-9]+.*|.*[wxq].+|.*[b,c,�,d,f-h,j-n,p-t,�,v,z,�]{4,}.*/) {
	print	"\n$R"."D�mesio$d, labai tik�tina, kad j�s �ved�te blog� �od�(jame negali b�ti skai�i�,\n\"sulipusi�\"(esan�i� greta) priebalsi� bei kai kuri� balsi�, lotyn� ab�c�l�s\nraid�i� [q,w,x]..ir kt.)!\n";
	return 0;
    }
    else { return 1; }
}
## main() pabaiga ##
print "$d\nIki!\n";


sub daikt_teisingas_balsis($) {
    my $word = shift;
    my $id = shift;
    my $msg;
    if ($id == 1) {
	print "\n\n$R"."D�mesio$d - tik�tina, kad �odis$B $word$d yra veiksma�odinis daiktavardis.\n"; 
	print "Tokie daiktavard�iai yra kil� i� veiksma�od�io(pvz. vytukas <- "; 
	print "vyti;\nirklas <- irti) ir savo �aknyje da�niausiai turi toki pat� bals�\n";
	print "kaip ir pamatinio veiksma�od�io bendraties forma.\n\n";
	print "$Y"."Pvz:\n";
	print "\t$B\-tuvas:$d v$G"."y$d"."tuvas (: v$G"."y$d"."ti); tr$G"."i$d"."ntuvas (: tr$G"."i$d"."nti); d$G"."u$d"."rtuvas (: d$G"."u$d"."rti)...\n";
	print "\t$B\-tas:$d b$G"."u$d"."rtas (: b$G"."u$d"."rti); k$G"."e$d"."ltas (: k$G"."e$d"."lti); sv$G"."e$d"."rtas (: sv$G"."e$d"."rti)...\n";
	print "\t$B\-kl�:$d b$G"."�$d"."kl� (: b$G"."�$d"."ti); �$G"."�$d"."kl� (: �$G"."�$d"."ti); v$G"."i$d"."rykl� (: v$G"."i$d"."rti)...\n\n";
    }
    elsif ($id == 2) {
	print "\n\n$R"."D�mesio$d - tik�tina, kad �odis$B $word$d yra veiksma�odinis daiktavardis.\n"; 
	print "Tokie daiktavard�iai yra kil� i� veiksma�od�io(pvz. veik�jas <- "; 
	print "veikia,veik�;\nra�inys <- ra�o,ra��) ir savo �aknyje da�niausiai turi toki pat� bals�\n";
	print "kaip ir pamatinio veiksma�od�io b�tojo kartinio laiko forma.\n\n";
	print "$Y"."Pvz:\n";
	print "\t$B\-imas:$d g$G"."y$d"."nimas (: g$G"."y$d"."n�); r$G"."i$d"."jimas (: r$G"."i$d"."jo); k$G"."�$d"."limas (: k$G"."�$d"."l�)...\n";
	print "\t$B\-inys:$d k$G"."�$d"."rinys (: k$G"."�$d"."r�); n$G"."�$d"."rinys (: n$G"."�$d"."r�); si$G"."u$d"."vinys (: si$G"."u$d"."vo)...\n";
	print "\t$B\-�sis:$d gri$G"."u$d"."v�sis (: gri$G"."u$d"."vo); d�i$G"."�$d"."v�sis (: d�i$G"."�$d"."vo); p$G"."u$d"."v�sis (: p$G"."u$d"."vo)...\n\n";
    }
    $msg = "Pasitikrinkite ar daiktavard�io �aknyje yra teisingas balsis?";
    if ( !taip_ne($msg, "t")) {
	$msg = "�veskite teising� �od� ($G"."q$d sugr��ti � prad�i�)";
	if (! ($word = ivesti_zodi($msg, $word)) ) {  return; };
    }
    return 1;
}

sub atidaryti_zodynus()
{
    use Fcntl qw(:DEFAULT :flock);
    my $home; 
    if($opt_p || $opt_P){
       	$_ = defined($opt_p) ? $opt_p : $opt_P;
	if(-d) {
	    if(/\/bin\/?.*|\/usr\/bin\/?.*|\/usr\/local\/bin\/?.*|\/sbin\/?.*|\/usr\/sbin\/?.*|\/usr\/X11R6\/?.*/) {
		print "$R"."B�t� neprotinga$d saugoti �odyn� failus $B$_$d direktorijoje.\n";
		print "Jei j�s manote kitaip - fixme($0, ".(__LINE__ - 2)." eilut�)\n";
		print "U�sispyriau, toliau neveiksiu! ;)\n";
		exit;
	    }
	    else { $home = $_; }
	}
	else { print "$R"."Klaida$d, n�ra tokios direktorijos: $B$_$d !\nBlogas programos rakto -(p|P) argumentas.\n"; exit; }
    }
    else{ $home = $ENV{"HOME"} || $ENV{"LOGDIR"} || (getpwuid($<))[7]; }
           
    foreach $key ( keys (%fn_h) ) {
	sysopen( $fh_h{$key},"$home/$fn_h{$key}", O_RDWR | O_CREAT) or die "\$n$R"."D�mesio$d\, negaliu atidaryti/sukurti /$home/$fn_h{$key} !";
	flock($fh_h{$key}, LOCK_EX) or die "\n$R"."D�mesio$d\, negaliu u�rakinti(lock) /$home/$fn_h{$key} !";    
    }

}
sub paieska_zodynuose($$) {
    my $word = shift;
    my $dalis_id = shift; # kokia kalbos dalis 1 - daiktavardis, 2 - veiksma�odis, 3 - b�dvardis, 4 - nekaitoma
    my ($str1, $msg, $ats);
    my $af = '';
    $found_i = 0;
    # paie�ka pagrindiniame ispell �odyne #
    open(FROM_ISPELL, "echo $word | ispell -d lietuviu -a | grep \'^[*,-,+,&,#,?]\' |") or die 	"\n$R"."D�mesio$d".", negaliu �vykdyti komandos \'echo $word | ispell -d lietuviu -a | grep \'^[*,-,+,&,#,?]\' \' !";
    $_ = <FROM_ISPELL>;
    close(FROM_ISPELL);
    if (/^\*/) {
	print "$R"."D�mesio$d".", �odis $B\'$word\'$d yra pagrindiniame ispell �odyne.\n";
	$found_i = 1;
	return;
    }
    elsif ( /^\+.(.*)$/ ) {
	print "$R"."D�mesio$d".", j�s� �vesta �od�io forma $B\'$word\'$d turi �aknin� �od� $G\'$1\'$d,\nkuris  yra pagrindiniame ispell �odyne.\n";
	$found_i = 1;
	return;
    }
    ##	   
    
    # TODO: tikrinti abu �odynus(tiek sukompiliuot�, tiek vartotojo) ir ie�koti galimai pasikartojan�i� �od�i�
    if ($dalis_id == 1) {
    # daiktavard�io paie�ka ~ direktorijoje esan�iuose �odynuose #
	foreach $key (1,2,3,9) {
	    if(find_in($fh_h{$key}, $word)) {
		$str1 = $fn_h{$key};
		$af = $_;
		last;
	    }
	}
    }##
    elsif($dalis_id == 2) {
    # veiksma�od�io paie�ka ~ direktorijoje esan�iuose �odynuose #
	foreach $key (4,5) {
	    if(find_in($fh_h{$key}, $word)) {
		$str1 = $fn_h{$key};
		$af = $_;
		last;
	    }
	}
    }##
    elsif($dalis_id == 3) {
    # b�dvard�io paie�ka ~ direktorijoje esan�iuose �odynuose #
	foreach $key (6,7) {
	    if(find_in($fh_h{$key}, $word)) {
		$str1 = $fn_h{$key};
		$af = $_;
		last;
	    }
	}
    }##
    elsif($dalis_id == 4) {
    # nekaitomo �od�io paie�ka ~ direktorijoje esan�iuose �odynuose #
	foreach $key (8,9,10) {
	    if(find_in($fh_h{$key}, $word)) {
		$str1 = $fn_h{$key};
		last;
	    }
	}
    }##
    if ($found_u) { print "\n$R"."D�mesio$d".", �odis $B$word$Y\/$af$d yra �odyne \'$str1\'.";  }
}  

sub taip_ne($$) {
    my $msg = shift;
    my $def_ans = shift;
    my $kart = 0;
    do {
	if ($kart > 3) { 
	    print "\n$d"."�veskite ($G"."t$d,$G"."n$d arba $G"."q$d): $B"; 
	}
	else { print "$msg ($G"."t$d\/$G"."n$d\) [$B"."$def_ans$d\]: $B"; }
    	$_ = <STDIN>;
	print "$d";
	if (!defined || /q/i) {  return; }
	chomp($_);
	$_ = $def_ans if $_ eq '';
	$kart++;
    } until /^[tnq]$/i;
    return (/t/i) ? 1 : 2;
}

sub ivesti_zodi($;$) {
    my $msg = shift;
    my $def_word = shift ;
    my $kart = 0;
    do {
	if($kart >= 3) { print "\n�veskite teising� �od� ($G"."q$d sugr��ti � prad�i�): $B"; } 
	else { 
	    if( defined($def_word) && $def_word ne '' ) { print "$msg [$B$def_word$d\]: $B"; }
	    else { print "$msg: $B"; }
	} 
	$_ = <STDIN>;
	print "$d";
	if (!defined || /q/i) {  return; }
	chomp ($_);
	if( $_ eq '' && defined($def_word) ) { $_ = $def_word; }
    } until (legal ($_) );
    return $_;
}

sub sub_exit {
    print "$d";
    exit;
}

sub irasyti_izodyna ($$) {
    my $id = shift;
    my $word = shift;
    my $lst_ref;
    my ($ats, $idx);
    
    my $msg = "\nJ�s� �vestas �odis yra? :";
    
    if ($id == 1) {
	$lst_ref = ['Lietuvi�kas daiktavardis', 'Taptautin�s kilm�s �od�io daiktavardis', 'Vardas', 'Kita (skaitvardis, �vardis)'];
	if(! ($ats = v_choice($msg, $lst_ref,  1 )) ) {  return; }
	else { $ats = ($ats == 4) ? 9 : $ats; }
    }
    elsif ($id == 2) {
	$lst_ref = ['Lietuvi�kas veiksma�odis', 'Taptautin�s kilm�s �od�io veiksma�odis'];
	if(! ($ats = v_choice($msg, $lst_ref,  1 )) ) {  return; }
	else { $ats += 3; }
    }
    elsif ($id == 3) {
	$lst_ref = ['Lietuvi�kas b�dvardis', 'Taptautin�s kilm�s �od�io b�dvardis'];
	if(! ($ats = v_choice($msg, $lst_ref,  1 )) ) {  return; }
	else { $ats += 5; }
    }
    elsif ($id == 4) {
	$lst_ref = ['Tiesiog nekaitomas (arba neai�kus) �odis', '�argonas'];
	if(! ($ats = v_choice($msg, $lst_ref,  2 )) ) {  return; }
	else { $ats = ($ats == 1) ? 8 : 10; }  
    }
    $idx = $ats;
    write_to($fh_h{$idx}, $word);

}

sub v_choice($$$) {
    my $msg = shift;
    my $lst_ref = shift;
    my $def = shift;
    my $tmp = 1;
    my $range;

    print "$msg\n";
    foreach $i (@$lst_ref) {
	print "\n\t\t$G$tmp$d $i";
	$tmp++;
	next;
    }
    print "\n\n";
    $range = $tmp--;
    $tmp = 0;
    do {
	if ($tmp >= 3) {
	    print "\n�veskite variant� atitinkant� skai�i� nuo $G"."1$d iki $G$range$d arba $G"."q$d i�eiti [$B$def$d]: $B" ;
	}
	else {	print "�veskite [$B$def$d]: $B"; }
	$_ = <STDIN>;
	print "$d";
	if (!defined || /q/i) {  return; }
	chomp($_);
	$_ = $def if $_ eq '';
	$tmp++;
    } until( /[1-$range]/ );
    return $_;
}

sub write_to($$)
{
    my $FH = shift;
    my $word = shift;

    seek($FH, 0, 1) or die "$R"."D�mesio$d\, negaliu pereiti � failo gal�.\n";
    print $FH "$word\n" or die "$R"."D�mesio$d\, negaliu �ra�yti � failo gal�.\n";
    print "�ra�yta\n";
}

sub find_in($$)
{
    my $FH = shift;
    my $word = shift;
    $found_u = 0;
    
    if (tell($FH)) { seek($FH, 0, 0) or die "$R"."D�mesio$d\, negaliu pereiti � failo prad�i�.\n"; }
    while ( <$FH> ) {
	if (/^$word(\/(.+))?$/i) {
	    $found_u = 1;
	    $_ = $2;
	    last;
	}
    }
    if ($found_u) {  return ($_) ? $_ : 1; }
}

sub append_flags($$$;$) {
    my $msg = shift;
    my $def = shift;
    my $f_true = shift;
    my $f_false = shift;
    my $ats = taip_ne($msg, $def);
    if(!$ats) {  return; }
    elsif($ats == 1) { $flags .= $f_true; }
    elsif($ats == 2 && defined($f_false)) { $flags .= $f_false; }
    return $ats;
}

sub veiks_tikrinimas (\$\$\$) {
    my $bend = shift;
    my $es = shift;
    my $but = shift;
    my ($msg, $ats);
    
    # Patikrinimas ar teisingai ra�mos nosin�s bals�s veiksma�od�i� �aknyse prie� raid� 's'
    if ( $$bend =~ /^(.*)(.)([aeiyu�])(s.*)$/i || $es =~ /^(.*)(.)([aeiyu�])(s.*)$/i ) {
	my ($_1, $_2, $_3, $_4) = ($1, $2, $3, $4);
	my $itart; # �tartina bendratis?(1), esamasis laikas?(0), abu?(2) 
	($$bend eq "$1$2$3$4") ? ($itart = 1) : ($itart = 0);
	if ($itart) { ($$es =~/$1$2$3s.*/i) ? ($itart = 2)  : ($itart = 1); }
	if ( $$es =~ /$1$2[aeiu]n.*/i || $$but =~ /$1$2[aeiu]n.*/i || $$bend =~ /$1$2[aeiu]n.*/i ) {
	    print "\n$R"."D�mesio$d\, nosin�s bals�s $B"."�$d\,$B"."�$d\,$B"."�$d\,$B"."�$d ra�omos veiksma�od�i� �aknyse prie� \'$d"."s$d\',\nkai pagrindiniuose kamienuose �ios bals�s kaitaliojasi su $G"."an$d\,$G"."en$d\,$G"."in$d\,$G"."un$d.\n$Y"."Pvz:$d\n\tgr$B\�$d\(s)ti : gr$G"."in$d"."d�ia, gr$G"."in$d"."d�; br$B"."�$d\(s)ti, br$B"."�$d\(s)ta : br$G"."en$d"."do...\n"; 
	    $_ = $_3;
	    if( /a/i ) { $_ = '�'; }
	    elsif( /e/i ) { $_ = '�'; }
	    elsif( /[u�]/i ) { $_ = '�'; }
	    elsif( /[iy]/i ) { $_ = '�'; }
	    my ($str1, $str2, $es_tb, $bend_tb); # $es_tb, $bend_tb - (t)ur�t� (b)�ti
	    print "-------------------------------------------------------------------------------";
	    if ($itart == 2) {
		my $tmp = $$es;
		$tmp =~ s/$_1$_2$_3(.*)/$_1$_2$G$_3$d$1/i;
	        $str1 = "\'$_1$_2$G$_3$d$_4\', \'$tmp\'";
		$tmp = $$es;
		$tmp =~ s/$_1$_2$_3(.*)/$_1$_2$_$1/i;
	        $es_tb = $tmp;
		$bend_tb = "$_1$_2$_$_4";
	        $tmp =~ s/^$_1$_2$_(.*)/$_1$_2$G$_$d$1/i ;
	        $str2 = "\'$_1$_2$G$_$d$_4\', \'$tmp\'";
            }
	    else { 
		$str1 = "$_1$_2$G$_3$d$_4"; 
		$str2 = "$_1$_2$G$_$d$_4"; 
		($itart == 0) ? ($es_tb = "$_1$_2$_$_4") : ($bend_tb = "$_1$_2$_$_4");  
	    }
	    do {
		print "\n$B"."J�s �ved�te$d $str1 nors taisykl� byloja, kad:\n$R"."Tur�t� b�ti$d $str2.\n";
		$msg = "Ar sutinkate su taisyke?";
		if(! ($ats = taip_ne($msg, 't')) ) {  return; }
		elsif($ats == 2) {
		    $msg = "Nereg�tas u�sispyrimas.. :). Belieka paklausti ar esate �sitikin�, kad �od�ius\n�ved�te teisingai?\n$$bend, $$es, $$but?";
		    if(! ($ats = taip_ne($msg, "n")) ) {  return; }
		
		}
		else { 
		    if($es_tb) { $$es = $es_tb; } 
		    if ($bend_tb) { $$bend = $bend_tb; }
		    print "\n$$bend, $$es, $$but\n";
		}
	    } while ($ats == 2);
	}
    }
    return 1;
}

sub pagalba() {
    system('clear');
    print "Programos veikimo $G"."principas$d\:\n\n";
    print "�od�i� kaupimas yra i�skirtas � 4 pagrindinius skyrius, tai yra:\n";
    print "    -$B Daiktavardis$d\n";
    print "    -$B Veiksma�odis$d\n";
    print "    -$B B�dvardis$d\n";
    print "    -$B Nekaitoma$d\n";
    print "    �vedus �od� bei pasirinkus skyri�, programa papra�ys �vesti �aknin� �od�io\n";
    print "form�(daiktavard�iams, b�dvard�iams  - vardininko laipsnis, veiksma�od�iams tai\n";
    print "yra bendratis, esamasis bei b�tasis kartinis laikai). S�voka \"�akninis �odis\"\n";
    print "rei�kia, kad �is �od�is kartu su nustatytais afiks� parametrais(v�liav�l�s) bus\n";
    print "i�saugotas �odyne.\n";
    print "    Toliau programa ie�ko j�s� �vesto �akninio �od�-io(i�) pagrindiniame bei \n";
    print "-(p|P) raktu nurodytoje arba nam� direktorijoje(/~) esan�iuose �odynuose.\n";
    print "    Jei �odis i� tikr�j� ne�inomas, programa kaip �manoma draugi�kiau papra�ys\n";
    print "suteikti jai paildom� informacij�(�od�io linksniai, laikai, prie�d�liai,\n";
    print "gal�n�s, kita) kuri reikalinga teisingiems �od�io afiksams nustatyti. Po vis�\n"; 
    print "�i� veiksm�, jums sutikus, �odis bus �ra�ytas � atitinkam� �odyn�.\n\n";
    print "    -$B Ctrl+D$d - bet kada gr��ta � programos prad�i�. Esant programos prad�ioje\n";
    print "�i kombinacija nutraukia jos vykdym�.\n";
    print "    -$B Ctrl+C$d - bet kada nutraukia programos vykdym�.\n";
}

sub usage()
{
print "$versija\n";
print "\nProgramos argumentai:\n\n";
print "-b, -B\tNenaudoti spalv�(�prastas, bespalvis tekstas)\n";
print "-f, -F\tFailas i� kurio bus skaitomi ir nagrin�jami �od�iai.\n\tNutyl�jus(nenurod�ius -f ar -F) bus skaitomi ir nagrin�jami vartotojo\n\t�vedami �od�iai\n";
print "-h, -H\tPagalba(�is programos argument� s�ra�as)\n";
print "-p, -P\tDirektorija, kurioje saugomi �odyno failai.\n\tNutyl�jus(nenurod�ius -p ar -P) tai yra vartotojo nam� direktorija /~\n";

}
