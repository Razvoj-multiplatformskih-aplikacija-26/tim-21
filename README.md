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

## Pokretanje

Potrebni su Docker (Docker Desktop na Windows-u) i Flutter. Sve komande se pokreću iz korena repozitorijuma.

### Baza i server

```sh
copy .env.example .env      # bash: cp .env.example .env
docker compose up -d --build
```

`compose.yaml` podiže tri servisa:

| Servis | Šta radi | Adresa |
| --- | --- | --- |
| `db` | PostgreSQL 17 | `localhost:5436` |
| `migrate` | dbmate primeni migracije iz `apps/server/migrations`, pa izlazi | — |
| `server` | server u Dartu na Relic-u, slika iz `apps/server/Dockerfile` | http://localhost:8080 |

Lozinka baze, `DEMO_PASSWORD`, `JWT_SECRET` i portovi su u `.env`, koji nije u git-u; u repozitorijumu je samo `.env.example` sa razvojnim vrednostima. Kada je baza prazna, server pri pokretanju upiše početne podatke, sa datumima računatim od trenutka podizanja.

Provera: `docker compose ps -a` (servis `migrate` je `Exited (0)`) i `curl http://localhost:8080/health` (odgovor `ok`; u PowerShell-u `curl.exe`).

| Komanda | Šta radi |
| --- | --- |
| `docker compose logs -f server` | ispis servera; `logs migrate` za migracije |
| `docker compose up -d --build server` | nova slika servera posle izmene u `apps/server` ili u paketima (npr. granice pravila u `domain`) |
| `docker compose stop server` / `start server` | gasi i pali samo server (provera poruke „Nema veze sa serverom.“) |
| `docker compose down` | gasi sistem, podaci ostaju |
| `docker compose down -v` | gasi sistem i briše bazu; sledeći `docker compose up -d --build` kreće od nule, sa svežim početnim podacima |

Ako je port zauzet, promenite ga u `.env`: `POSTGRES_PORT` (i isti port u `DATABASE_URL`) ili `SERVER_PORT` (aplikacije tada pokrenite sa `--dart-define=SERVER_URL=http://localhost:<port>`).

Testovi servera traže pokrenutu bazu (`docker compose up -d db migrate`): `cd apps/server`, pa `dart test`.

### Aplikacije

Jednom, iz korena, za ceo workspace:

```sh
flutter pub get
```

Svaka aplikacija u svom terminalu:

```sh
cd apps/mobile
flutter run                                 # Android emulator
```

```sh
cd apps/backoffice
flutter run -d windows
flutter run -d chrome --web-port 8081       # backoffice u pregledaču
```

Za `flutter run -d windows` Windows traži uključen Developer Mode (`start ms-settings:developers`), jer Flutter pravi simboličke veze za dodatke (`flutter_secure_storage`), a Visual Studio komponentu **C++ ATL** (Visual Studio Installer → Desktop development with C++ → C++ ATL).

Adrese servera:

- **Android emulator** vidi računar na `10.0.2.2`, pa mobilna zove `http://10.0.2.2:8080`. Telefon na istoj mreži: `flutter run --dart-define=SERVER_URL=http://<IP računara>:8080`.
- **Windows** zove `http://localhost:8080`.
- **Pregledač** sme da zove server samo sa porekla navedenog u `CORS_ORIGINS` u `.env`; `.env.example` dozvoljava `http://localhost:8081`, zato backoffice u Chrome-u ide uz `--web-port 8081`. Više porekla se odvaja zarezom; `*` se ne koristi, jer ga pregledač uz kolačić ne prihvata. Posle izmene: `docker compose up -d server`.

Obe aplikacije traže prijavu na ulazu. Mobilna prima samo članove, a backoffice samo osoblje.

### Demo nalozi

Lozinka za sve naloge je vrednost `DEMO_PASSWORD` iz `.env` (u `.env.example`: `boardgame-demo`). U bazi je samo njen Argon2id heš.

| Nalog | Uloga | Aplikacija |
| --- | --- | --- |
| `clan1`, `clan2`, `clan3` | član | mobilna |
| `bibliotekar1` | osoblje (bibliotekar) | backoffice |

U početnim podacima je 6 igara sa po 1–3 kopije i pozajmice u svim stanjima. Carcassonne ima tačno jednu slobodnu kopiju i dva zahteva na čekanju za nju, od `clan1` i `clan2`: posle odobravanja jednog, drugo odobravanje dobija „Nema slobodne kopije ove igre.“ `clan3` ima preuzetu pozajmicu kojoj je rok prošao (kasni), pa ne može da šalje nove zahteve.

### Istek prijave za demonstraciju

Prijava podrazumevano traje 480 minuta. Za demonstraciju isteka u `.env` postavite `SESSION_TTL_MINUTES=1` i ponovo napravite kontejner servera:

```sh
docker compose up -d server
```

Minut posle prijave sledeći poziv dobija 401 `session-expired`, a aplikacija se vraća na ekran za prijavu sa porukom „Prijava je istekla. Prijavite se ponovo.“ Posle demonstracije vratite `SESSION_TTL_MINUTES=480` i ponovite istu komandu.

### Skripta za testiranje

`apps/server/tool/demo.ps1` zove pokrenuti server preko `curl.exe` i za svaku proveru ispisuje zahtev, očekivani i dobijeni status i telo odgovora. Lozinku čita iz `.env`.

```powershell
powershell -File apps/server/tool/demo.ps1                     # sve provere redom
powershell -File apps/server/tool/demo.ps1 -Check duration     # samo jedna
```

| `-Check` | Šta radi | Očekivano |
| --- | --- | --- |
| `login` | `clan1` se prijavljuje kao aplikacija (`cookie: false`) | 201, `SessionDto` sa tokenom |
| `duration` | `clan1` traži pozajmicu na 8 dana | 422 `invalid-loan-duration`, `max: 7` |
| `approve-as-member` | `clan1` šalje odobravanje svog zahteva | 403 `not-allowed` |
| `cancel-other` | `clan1` otkazuje pozajmicu člana `clan2` | 404 `not-found` |
| `no-token` | poziv bez tokena | 401 `sign-in-required` |
| `race` | dva istovremena odobravanja (`Start-Job`) za Carcassonne, igru sa jednom slobodnom kopijom | jedno 200, drugo 409 `no-free-copy` |

Skripta izlazi sa 0 kada su svi statusi očekivani. Provera `race` odobri jedinu kopiju Carcassonne-a, pa se ponavlja tek nad bazom od nule:

```sh
docker compose down -v
docker compose up -d --build
```
