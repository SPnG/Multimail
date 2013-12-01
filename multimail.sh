
xmldatei="$HOME/patienten.xml"

if [ ! -e $xmldatei ]; then
   zenity --error "Datenrecherche-Exportdatei $xmldatei nicht gefunden. Abbruch."
   exit1
fi

patliste=`mktemp /tmp/patliste.XXXXXXXX`
patliste1=`mktemp /tmp/patliste1.XXXXXXXX`
patliste2=`mktemp /tmp/patliste2.XXXXXXXX`
datrechmailprg=`mktemp /tmp/datrechmailprg.XXXXXXXX`
datrechmailprg1=/tmp/mr1.prg
datrechmailtmp1=`mktemp /tmp/datrechmailtmp1.XXXXXXXX`
datrechmailtmp2=`mktemp /tmp/datrechmailtmp2.XXXXXXXX`

grep -Po "(?<=<patnr>)[^<]*(?=</patnr>)" $xmldatei > $patliste
MAILkenn="PEMA"
NNkenn="3101"
VNkenn="3102"
ORTkenn="3106"
STRkenn="3107"

> $datrechmailtmp1
for i in `cat $patliste`; do
   docbdtex -d $i $patliste1 > /dev/null
# der Befehl sed 's/.$//' schneidet das letze Zeichen im String ab (ist ein CR)
   ema=`cat $patliste1|fgrep "$MAILkenn"|cut -c 8-|sed 's/.$//'`
   if [ ! -z $ema ]; then
      nn=`cat $patliste1|fgrep "$NNkenn"|cut -c 8-|sed 's/.$//'`
      vn=`cat $patliste1|fgrep "$VNkenn"|cut -c 8-|sed 's/.$//'`
      ort=`cat $patliste1|fgrep "$ORTkenn"|cut -c 8-|sed 's/.$//'`
      str=`cat $patliste1|fgrep "$STRkenn"|cut -c 8-|sed 's/.$//'`
      echo "$nn $vn;$ort $str;$ema" >> $datrechmailtmp1
   fi  
   rm -f $patliste1
done 


echo -e "\n" > $datrechmailprg1 
# Teil 1 des zenity-Aufrufs in Programmdatei einfügen:
txt="                                     Email-Liste aller Patienten aus Datenrecherche                                     "
echo "ans=\$(zenity --list --text "\""$txt"\" --multiple --print-column=4 --checklist --column "\"""\"" --column "\""Patient"\"" --column "\""Ort"\""  --column "\""Email"\"" >> $datrechmailprg1

# Patientenliste einfügen
iconv -f ISO-8859-1 -t UTF-8 $datrechmailtmp1 | sort > $datrechmailtmp2
cat $datrechmailtmp2 | awk -F";" '{print " FALSE ""\""$1"\" ""\""$2"\" ""\""$3"\""}' >> $datrechmailprg1
echo " --separator=\":\"); echo \$ans" >> $datrechmailprg1
# Zeilenumbrüche aus Datei entfernen 
tr -d "\n" < $datrechmailprg1 > $datrechmailprg
chmod 775 $datrechmailprg
# zenity-Programm ausführen
ret=`$datrechmailprg`
# Rückgabe auswerten
if [ -z "$ret" ]; then
   zenity --info --text="nichts ausgewält"
else
   echo $ret|awk -F":" '{for (i=1;i<=NF;i++)print $i}'
fi

# rm -f $xmldatei
rm -f $patliste
rm -f $patliste1
rm -f $patliste2
rm -f $datrechmailprg
rm -f $datrechmailprg1
rm -f $datrechmailtmp1
rm -f $datrechmailtmp2

