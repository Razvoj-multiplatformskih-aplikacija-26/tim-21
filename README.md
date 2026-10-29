# BoardGame Booking

Aplikacija za biblioteku društvenih igara: članovi pozajmljuju igre na nekoliko dana, a biblioteka ima ograničen broj kopija svake igre. Članovi preko mobilne aplikacije pregledaju katalog, šalju zahteve za pozajmicu, upisuju se na listu čekanja za igre koje su trenutno izdate i prate rokove vraćanja, a osoblje u aplikaciji upravlja inventarom kopija, izdavanjem i povraćajem igara i listama čekanja.

## Tim

| Ime i prezime    | Broj indeksa | GitHub nalog                                 |
| ---------------- | ------------ | -------------------------------------------- |
| Boris Gočmanac   | SI 96/24     | [@Bilok66](https://github.com/Bilok66)       |
| Boris Živanović  | SI 62/24     | [@risboo4](https://github.com/risboo4)       |

## Zahtevi za temu

### 1. Uloge

Sistem ima tri uloge: **član** (traži pozajmice, upisuje se na liste čekanja, produžava rok i vodi listu želja; vidi samo svoje podatke), **bibliotekar** (osoblje koje odobrava zahteve, izdaje i prima kopije igara, proverava da li su svi delovi igre vraćeni i vodi evidenciju o oštećenjima) i **menadžer** (upravlja katalogom igara, brojem kopija, pravilima pozajmljivanja i osobljem, i može da odbije ili otkaže bilo koju pozajmicu). Član vidi samo svoje pozajmice i liste čekanja, a osoblje vidi sve pozajmice biblioteke.

### 2. Stanja

Pozajmica prolazi kroz stanja: na čekanju (zahtev poslat) -> odobrena (kopija rezervisana za člana) -> preuzeta (kopija izdata) -> vraćena (kopija vraćena i proverena), uz stanje kasni (preuzeta, a rok vraćanja je istekao) i bočna stanja odbijena (osoblje ne prihvata zahtev) i otkazana (član ili biblioteka otkazuje pre preuzimanja, ili odobrena pozajmica nije preuzeta u roku).

### 3. Pravila

- Član može istovremeno imati najviše 3 aktivne pozajmice, a jedna pozajmica traje najviše 7 dana.
- Broj istovremeno izdatih i rezervisanih kopija jedne igre ne može preći broj kopija koje biblioteka poseduje.
- Kada nema slobodne kopije, član se upisuje na listu čekanja; kada se kopija vrati, rezerviše se za prvog na listi i čeka ga 48 sati, posle čega prelazi na sledećeg.
- Rok se može produžiti jednom, i to samo ako za tu igru nema nikoga na listi čekanja.
- Član sa pozajmicom u stanju "kasni" ne može da šalje nove zahteve dok je ne vrati.
- Odobrena pozajmica koja nije preuzeta u roku od 2 dana automatski se otkazuje.

Pravila o kopijama, listi čekanja i produženju zavise od podataka drugih članova, pa o njima konačno odlučuje server.

### 4. Rad bez mreže

Član bez signala može da otkaže zahtev ili odobrenu pozajmicu, zatraži produženje roka, upiše se na listu čekanja i izmeni listu želja; izmene se čuvaju lokalno i šalju serveru kada se veza vrati, uz razrešavanje sukoba (npr. produženje odbijeno jer se u međuvremenu neko upisao na listu čekanja, otkazivanje odbijeno jer je igra već preuzeta, ili mesto na listi čekanja koje je u međuvremenu zauzeo drugi član). Pregled aktivnih pozajmica sa rokovima vraćanja i katalog igara dostupni su i bez mreže.

### 5. Posao za osoblje

Osoblje radi sa tablom izdavanja i povraćaja (sve pozajmice sa filtriranjem po stanju, igri, članu i roku, uz isticanje onih koje kasne), inventarom svih kopija (slobodna, rezervisana, izdata, u proveri, oštećena) i listama čekanja po igrama, uz potvrdu zahteva na čekanju, evidenciju provere delova pri vraćanju i grupne radnje nad većim brojem pozajmica.

### 6. Javni sadržaj

Bez prijave su dostupni: katalog društvenih igara (opis, broj igrača, trajanje partije, težina) sa filtriranjem, trenutna dostupnost kopija i dužina liste čekanja, pravila pozajmljivanja, radno vreme biblioteke i novo u ponudi.
