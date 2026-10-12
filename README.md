# BoardGame Booking
 
BoardGame Booking - Aplikacija za rezervaciju termina u kafiću za društvene igre. Nema fiksnih vremenskih slotova: gosti preko mobilne aplikacije biraju početno vreme i koliko sati ostaju, unose koliko će ih biti, a sistem im ponudi stolove odgovarajućeg kapaciteta koji su slobodni u tom intervalu. Uz rezervaciju mogu unapred da zakažu i određene društvene igre, kako dve grupe ne bi u istom periodu tražile igru koje kafić nema u dovoljno kopija. Osoblje u backoffice aplikaciji upravlja rasporedom stolova, katalogom igara i tokom svake posete.

## Tim

| Ime i prezime | Broj indeksa |
| ------------- | ------------ |
| Boris Gočmanac   | SI 96/24     |
| Boris Živanović   | SI 62/24     |

## Zahtevi za temu
 
### 1. Uloge
 
Sistem ima tri uloge: **gost** (upravlja svojim rezervacijama i listom želja igara, vidi samo svoje podatke), **domaćin** (osoblje koje vidi dnevni raspored, potvrđuje zahteve, evidentira dolazak gostiju, deli igre i označava kraj posete) i **menadžer** (upravlja stolovima, katalogom igara i brojem kopija, radnim vremenom i osobljem, i može da odbije ili otkaže bilo koju rezervaciju). Gost vidi samo svoje rezervacije, a osoblje vidi sve rezervacije kafića.
 
### 2. Stanja
 
Rezervacija prolazi kroz stanja: na čekanju -> potvrđena -> gosti stigli (sto zauzet, igre izdate) -> završena, uz bočna stanja odbijena (osoblje ne prihvata zahtev), otkazana (gost ili kafić otkazuje pre dolaska) i nije se pojavio (gosti nisu došli u toku tolerancije).
 
### 3. Pravila
 
Server gostu nudi samo stolove koji su slobodni tokom celog izabranog intervala (od početka do kraja boravka) i čiji kapacitet odgovara broju igrača, pa broj igrača ne može preći kapacitet stola, a isti sto ne može biti rezervisan dvaput u preklapajućim intervalima (ako ga u međuvremenu zauzme drugi gost, potvrda se odbija i nudi se nova lista). Broj rezervisanih kopija jedne igre u preklapajućim intervalima ne može preći broj kopija koje kafić poseduje, isti gost ne može imati dve rezervacije koje se vremenski preklapaju, a otkazivanje je moguće najkasnije 2 sata pre početka rezervacije, a trajanje boravka mora biti u dozvoljenim granicama (npr. najmanje 1 sat, najviše 6 sati). Pravila o stolovima i kopijama igara zavise od rezervacija drugih gostiju, pa o njima konačno odlučuje server.
 
### 4. Rad bez mreže
 
Gost bez signala može da otkaže rezervaciju, smanji broj igrača i izmeni listu želja igara; izmene se čuvaju lokalno i šalju serveru kada se veza vrati, uz razrešavanje sukoba (npr. otkazivanje odbijeno jer je gost u međuvremenu evidentiran kao stigao, ili kopija igre koju je gost dodao više nije dostupna). Pregled zakazanih rezervacija i kataloga igara dostupan je i bez mreže.
 
### 5. Posao za osoblje
 
Osoblje radi sa dnevnim rasporedom svih stolova (vremenska osa sa rezervacijama različitog trajanja po stolu), sa pregledom zauzetosti kopija svake igre po vremenskim intervalima, uz filtriranje po broju igrača, stolu i igri i potvrdu zahteva na čekanju.
 
### 6. Javni sadržaj
 
Bez prijave su dostupni: katalog društvenih igara (opis, broj igrača, trajanje partije, težina), meni i cenovnik, radno vreme, slobodni stolovi po broju igrača za izabrani datum, početno vreme i trajanje boravka, raspored događaja (turniri, večeri određenih igara) i informacije o stolovima.
