# GDC Resolve Encoder — reguli de arhitectură

> **[SYSTEM DIRECTIVE FOR CLAUDE: DO NOT DELETE OR OVERWRITE EXISTING RULES. ONLY APPEND NEW RULES.]**
> Jurnal viu, nu document care se rescrie. La orice actualizare, adaugă la finalul secțiunii potrivite — nu șterge/înlocui reguli vechi decât dacă sunt explicit invalidate de o schimbare reală (și atunci marchează-le **[ÎNVECHIT]** cu motivul, nu le șterge din istoric).

Citit automat de Claude Code la fiecare sesiune în acest repo.

## [PARTEA 1: REGULI GLOBALE ECOSISTEM GDC — identică în toate proiectele GDC]

> Acest bloc e sincronizat manual în `CLAUDE.md`-ul TUTUROR proiectelor din
> `~/Developer/` (CGConvertor, CursorPro, DataMover, GDCPluginManager,
> GDCPluginManagerWin, GDCVault, GDCVaultWin, gdc-plugin-manager-catalog-vendor,
> gdc-plugin-manager-files, gdc-production-manager, gdc-resolve-encoder, și
> orice proiect GDC nou). Dacă modifici o regulă aici, propag-o manual și în
> celelalte 10 fișiere — nu există un fișier partajat/include, fiecare
> `CLAUDE.md` e citit independent per-repo. Vezi jurnalul "Sincronizare
> CLAUDE.md" din secțiunea Partea 2 a fiecărui repo pentru data ultimei
> unificări.

**1. Directoare & structură.** Toate proiectele GDC trăiesc exclusiv în
`~/Developer/<NumeProiect>/`, niciodată în `~/Downloads` sau `~/Desktop`
(curățate automat de CleanMyMac/Hazel pe acest Mac — au șters repo-uri de
sursă în trecut). Niciun repo nou nu se creează/clonează în afara
`~/Developer/`. Certificatele Apple (`.p12`/`.cer`) și orice cheie privată
(`.p8`/`.key`/`.pem`/`.mobileprovision`) stau EXCLUSIV în
`~/Developer/Certificates/` (folder în afara oricărui repo git) — niciodată
comise, indiferent de `.gitignore`.

**2. Securitate — zero secrete în git.** `.git/config` nu conține niciodată
un token în clar în URL-ul remote-ului (`https://user:TOKEN@github.com/...`)
— autentificare exclusiv prin `gh` (credential helper) sau SSH. Orice token
găsit expus se elimină din config imediat; revocarea efectivă din GitHub
Settings e un pas manual al lui Cristi (Claude nu poate revoca un token).
Un secret comis vreodată în istoricul git (verificat cu
`git log --all -p | grep` sau echivalent) trebuie semnalat explicit, nu doar
curățat din starea curentă.

**3. Licențiere & Donație (GDC Plugin Manager / Furnizor).** Toate
aplicațiile standalone GDC folosesc `LicenseCore`/`MachineID` (Ed25519,
aceeași cheie publică hardcodată în tot ecosistemul — copiată byte-for-byte,
NU printr-o dependință de pachet între repo-uri). Probă gratuită implicită:
**15 zile**. Activare manuală prin WhatsApp (ID de mașină pre-completat) →
cod generat din `GenerateSerialView.swift` (Furnizor, `gdcStandaloneProducts`
trebuie să includă `productID`-ul noii aplicații). Valoarea susținerii
aplicației se exprimă EXCLUSIV ca **donație** — sumă implicită de referință
**23 €** dacă nu există alt preț promoțional documentat pentru acea
aplicație — NICIODATĂ cu cuvintele „preț", „cumpără" sau „vânzare" (RO/EN/ES:
niciodată „price"/„buy"/"sale" nici în engleză/spaniolă). Formularea trebuie
să apară clar în: UI-ul aplicației (ecran/pop-up de licență), ghidul PDF, și
orice pagină web dedicată.

**[COMPLETARE 2026-08-26, închide o lacună de scop reală]** Interdicția de
mai sus se aplică ACUM și produselor din catalogul GDC Plugin Manager
(LUT/DCTL/PowerGrade vândute prin marketplace-ul gratuit) — găsit la audit
un card cu buton „Cumpără" și sume afișate brut („378,00 €"). Butonul
devine „Donează" peste tot (RO/EN/ES); suma documentată de furnizor pentru
acel produs (promoția specifică lui, nu neapărat 23 €) rămâne vizibilă, dar
NICIODATĂ lângă cuvântul „preț"/„cumpără"/„vânzare" — decizia anterioară de
scop (marketplace = "relație comercială diferită, nu se aplică") e
INVALIDATĂ explicit. Excepție: tabelele interne ale Furnizorului (ex.
`SalesHistoryView`, coloana „Preț" din registrul de vânzări al lui Cristi)
nu sunt UI orientat spre client — rămân neatinse.

**15. CRM Furnizor — set minim de funcționalități administrative
(2026-08-26).** Panoul de Clienți al Furnizorului (`SalesHistoryView.swift`)
nu rămâne un log rigid — trebuie să ofere: filtrare rapidă pe produs
(dropdown dinamic, nu hardcodat), export 1-click (clipboard sau fișier) al
email-urilor/HWID-urilor din selecția curentă (filtrată), copiere rapidă
per-câmp direct din tabel (fără să deschizi editarea), Licențiere în Masă
(paste o listă de email-uri/machine ID-uri → generează automat câte o
licență per linie, pentru un produs/durată alese o singură dată), și
editare liberă a duratei unei licențe deja generate (Zile/Luni/Ani/
Lifetime). Furnizorul arată versiunea curentă în UI, la fel ca orice
aplicație client — nu e scutit de Regula 7 doar pentru că e un instrument
intern.

**16. Design Web "Shift" — compact, fără spații goale (2026-08-26).**
Completare la Regula 12: paginile de prezentare NU doar adoptă paleta
amber/cupru — trebuie și dense/aerisite corect, nu găunoase. `min-height:
100svh` pe un hero cu conținut scurt lasă spațiu gol enorm pe orice ecran
mai mare — evită-l sau limitează-l (ex. `78svh`); padding-ul secțiunilor
(`section`) rămâne generos dar nu excesiv (60px, nu 90px+). Orice accent
vechi (verde/teal/albastru folosit ca accent PRIMAR, nu ca stare
semantică precum "verificat cu succes") se înlocuiește cu amber/cupru —
o variabilă CSS poate păstra alt NUME istoric (`--scope`, `--accent-copy`)
atât timp cât VALOAREA ei devine amber, ca să nu rescrii zeci de
apariții `var(--x)` din foaia de stil.

**4. Manager de Dependențe (Standard GDC, opt-in).** Aplicația de bază
rămâne lightweight — orice dependință externă opțională/grea (ex. FFmpeg
static) se descarcă LA CERERE, nu bundle-uită implicit dacă poate fi evitat.
Indicator global 🔴/🟢 vizibil în header/meniu: verde doar dacă TOATE
componentele obligatorii (non-opționale) sunt OK; componentele opționale
(ex. Homebrew pe Mac) nu blochează starea verde. Click pe indicator deschide
un panou dedicat ("Verificare & Dependențe Sistem") cu o listă modulară de
componente (model generic `DependencyItem` — id, nume, opțional/obligatoriu,
verificare headless, acțiune, niciodată câmpuri hardcodate per-dependință),
fiecare cu propriul status + buton de acțiune (descărcare automată a unui
binar static, sau copiere comandă de instalare). Verificarea rulează headless
la fiecare deschidere a panoului/meniului, actualizând starea instant.

**5. Instalare Autonomă.** Mac: `.pkg` semnat Developer ID Application +
Installer, notarizat, stapled, cu `pkgbuild --install-location "/"` și
payload la `Applications/<App>.app` — instalare DIRECTĂ în `/Applications`
la dublu-click, fără drag-and-drop manual (verificabil cu
`pkgutil --payload-files`). Windows: installer Inno Setup cu
`DefaultDirName={autopf}\GDC\<App>` (Program Files) sau varianta x86,
scurtături automate Desktop + Start Menu, dezinstalare nativă prin
"Apps & Features" (fără script separat necesar dacă Inno Setup o acoperă).

**6. Packaging Mac — arhivă cu STRICT 3 fișiere.** Orice
`<App>-Mac.zip` livrat clientului conține la rădăcină EXACT: (1)
executabilul/`.pkg`-ul semnat+notarizat+stapled, (2)
`Dezinstalare_<App>.command` (dezinstalare completă: procese, TCC dacă
relevant, `~/Library/Application Support`, `Caches`, `Preferences`,
`Saved Application State`, `Logs`, orice item Keychain scris de aplicație),
(3) `Instructiuni_Utilizare.pdf` (RO/EN/ES). NICIODATĂ hack-uri
`xattr -dr com.apple.quarantine` sau launchere `Instalare_*.command` —
pachetul stapled e acceptat nativ de Gatekeeper. Curățarea unei instalări
vechi se face în `installer/scripts/preinstall` (`pkgbuild --scripts`,
pkill + `rm -rf`), niciodată legat de quarantine.

**7. UI Standard — varianta "Shift".** Temă dark, profesională, inspirată de
paginile de Color din DaVinci Resolve (fundal `#14161A`/`#1A1D22`, accent
cald cupru/amber sau altă culoare distinctă per-aplicație, text `#EDEFF2`).
Număr de versiune vizibil în UI (About/Meniu/Settings/Footer), fără excepție.
Update Checker automat la lansare + verificare manuală, conectat la
`update.json`/GitHub Releases API, cu notificare atât banner discrét CÂT ȘI
pop-up modal (o singură dată per versiune nouă, stare de dismissal comună
între cele două) — un simplu banner nu e suficient. `mandatory: true` în
`update.json` ignoră dismissal-ul anterior.

**8. Documentație PDF — standard ultra-detaliat.** Orice
`Instructiuni_Utilizare.pdf` (RO/EN/ES) se redactează pentru un utilizator
complet începător, zero presupuneri, cu secțiunile relevante aplicației:
(a) Panoul de Dependențe — ce înseamnă 🔴/🟢, pas-cu-pas ce face userul la
roșu (unde dă clic, ce se deschide, ce buton apasă); (b) Homebrew (Mac,
dacă aplicabil) — pași la nivel de acțiune: copiază comanda din aplicație,
deschide Terminal (Spotlight, `⌘+Space`), lipește (`⌘+V`), Enter, apoi
explică parola de Mac cerută (invizibilă la tastare) + Enter din nou;
(c) Fluxul de utilizare + acțiuni post-proces — cum se adaugă
fișiere/date, ce face fiecare buton rezultat; (d) Licență & Donație — trial
gratuit explicit (zile), suma exactă ca donație (niciodată "preț"/"vânzare");
(e) Cum funcționează actualizarea automată — ce înseamnă pop-up-ul de
versiune nouă, ce face butonul „Actualizează acum" vs „Mai târziu", și că
instalarea noii versiuni rămâne un pas asistat (descărcare + reinstalare),
nu un update silențios în fundal.

**9. Checklist obligatoriu la FIECARE release** (păstrat identic cu
"DIRECTIVĂ PERMANENTĂ SUPREMĂ" din jurnalul fiecărui proiect — punctele
1-4 de acolo sunt subsumate integral de punctele 5-8 de mai sus). Site-ul
public al fiecărei aplicații trebuie să pointeze mereu la
`releases/latest/download/...` (HTTP 200 verificat, nu presupus), niciodată
un tag fix.

**10. Comunicare & jurnal.** Fiecare `CLAUDE.md` rămâne un jurnal
append-only (regulile vechi nu se șterg, doar se marchează
**[ÎNVECHIT]** cu motivul dacă sunt explicit invalidate). Răspunsurile
Claude rămân ultra-concise: fără explicații de proces, direct codul/
diff-ul/comenzile și statusul. La orice modificare de cod, comanda exactă
de rebuild local se include la finalul răspunsului.

**11. Sincronizare dinamică a Standardului Master (CONTINUOUS UPDATE,
2026-08-26).** Orice adăugare/modificare/optimizare a unei reguli globale
din ACEASTĂ Partea 1 — indiferent din ce proiect pornește — devine automat
noul Standard Master și TREBUIE propagată manual, în ACELAȘI commit sau
imediat următorul, în `CLAUDE.md`-ul tuturor celorlalte proiecte din
`~/Developer/` (nu doar notată "pentru mai târziu"). Orice aplicație NOUĂ
creată în `~/Developer/` primește Partea 1 (versiunea curentă, completă)
încă din primul `CLAUDE.md` scris pentru ea — nu se pornește niciodată de
la un fișier gol sau parțial. Regula 1 de mai sus ("Dacă modifici o regulă
aici, propag-o manual...") descrie mecanismul; aceasta îl declară
obligatoriu, nu opțional.

**12. Profil Utilizator/HWID în Sidebar, Sistem de Revocare Licențe &
Standard Design Web Mobile/Desktop "Shift" (2026-08-26).**
- **Profil Utilizator opțional, vizibil în sidebar-ul UI** (Mac + Windows,
  pe toate aplicațiile cu licențiere GDC): Nume (sau „Anonim" dacă nu e
  completat), Email, și Machine ID (HWID) — afișate clar, nu ascunse
  într-un submeniu. Portat din modulul Tracker existent (Mac,
  `AnalyticsClient.registerDevice` → Supabase `devices`) — Windows trebuie
  aliniat la aceeași infrastructură, nu una separată.
- **Revocare/blacklist de licențe, prin Supabase** (ACEEAȘI bază de date
  deja folosită de Tracker — niciun backend nou de construit). O licență
  Ed25519 rămâne verificată local (offline-first, nicio schimbare la
  activarea inițială), dar clientul verifică periodic + la lansare (dacă
  există conexiune) un tabel de revocări după `machineID`/serial. **Fail
  OPEN, nu fail closed**: fără conexiune la internet, o licență deja
  activată local CONTINUĂ să funcționeze (nu bricuim un user legitim offline)
  — revocarea se aplică abia la următoarea verificare online reușită.
  Furnizor capătă unelte de revocare instant + editare a perioadei de
  valabilitate a unei licențe existente deja generate.
- **Generare flexibilă de licențe** (Furnizor): selector explicit al
  duratei — Zile / Luni / Ani / Forever (Lifetime) / Valabil până la
  versiunea X — nu doar trial fix + activare permanentă binară.
- **Standard Design Web "Shift"** — orice pagină de prezentare/descărcare
  GDC (`gordas.dev` și paginile dedicate per-aplicație) adoptă design-ul
  dark, minimalist, accent amber/cupru consacrat de CG Convertor
  (`gordas.dev/cg-convertor`) — niciun accent verde vechi sau stil
  nealiniat. Toate paginile trebuie optimizate explicit pentru mobil
  (iOS Safari + Android Chrome), verificat vizual la lățimi de telefon,
  nu doar "responsive by CSS framework".

**13. Update Checker — specificație UX obligatorie (2026-08-26).** La
lansare, aplicația verifică `update.json`/GitHub Releases; dacă versiunea
locală e mai veche, arată un pop-up/modal Shift (nu doar bannerul discret
din Regula 7) cu: numărul noii versiuni, un rezumat scurt al noutăților
(Release Notes, dacă `update.json` le are — câmp opțional, degradează
elegant dacă lipsește), și DOUĂ butoane explicite — **„Actualizează acum"**
(deschide direct link-ul de descărcare a installer-ului/pachetului nou,
`releases/latest/download/...`, și arată userului că trebuie să
instaleze peste versiunea curentă + repornească aplicația — NU e un
self-update silențios, niciun helper nu înlocuiește bundle-ul/exe-ul în
fundal, vezi WARNING-ul deja existent din `UpdateChecker.swift`/`.cs`) și
**„Mai târziu"** (închide fereastra, aceeași stare de dismissal ca
bannerul). Popup-ul apare o singură dată per versiune nouă, cu excepția
`mandatory: true` (reapare la fiecare lansare). Ghidul PDF (Regula 8(e))
trebuie să explice acest flux exact.

**14. Versionare semantică obligatorie la FIECARE schimbare (2026-08-26).**
Orice modificare de cod livrată clientului — oricât de mică — incrementează
numărul de versiune, sincron în TOATE punctele care îl țin (Info.plist Mac,
`.csproj`/`installer.iss` Windows, `docs/update.json`, orice altă constantă
de versiune din acel repo). Format `MAJOR.MINOR.PATCH` (ex. `2.3.1`):
- **PATCH** (ultima cifră, `2.3.0`→`2.3.1`) — orice fix, ajustare, adăugare
  mică sau schimbare care nu rupe compatibilitatea. Cazul implicit, cel mai
  frecvent.
- **MINOR** (cifra din mijloc, `2.3.x`→`2.4.0`) — funcționalitate nouă
  vizibilă (ex. o fază/etapă întreagă ca Panoul de Dependențe sau Profilul
  HWID), fără schimbări radicale de arhitectură.
- **MAJOR** (prima cifră, `2.x.x`→`3.0.0`) — schimbare radicală: rebranding,
  redesign complet de UI, schimbare de arhitectură (ex. sistem nou de
  licențiere), sau orice prag pe care Cristi îl declară explicit "versiune
  majoră".
**De ce**: `UpdateChecker`/`.cs` compară STRICT numărul de versiune din
`update.json` cu cel instalat (`IsNewer`) — înlocuirea unui binar pe un
release existent, PE ACEEAȘI versiune, nu declanșează nicio notificare la
clienții deja instalați (bug real, găsit și reparat 2026-08-26: Windows
Shift UI + Faza 1/3/4 livrate silențios sub `v1.2.22`, fără niciun bump).
Un bump de versiune fără schimbare reală de cod e la fel de greșit ca
schimbarea de cod fără bump — cele două merg mereu împreună, în același
commit.

**17. Orice fișier descărcabil TREBUIE să poarte numărul versiunii în NUMELE
fișierului (2026-08-26).** Nu doar în interiorul aplicației (Regula 14) —
în numele fizic al pachetului: `DataMover-2.5.5.pkg`, nu `DataMover.pkg`;
`GDCPluginManagerSetup-1.2.8.exe`, nu `GDCPluginManagerSetup.exe`. Motiv
direct de la Cristi: probele/build-urile de test se acumulează local (în
`~/Downloads`, `/tmp`, trimise pentru testare) și devin de nerecunoscut
fără versiune în nume — "am o grămadă de descărcări și nu știu ce versiune
sunt, care, ce și cum sunt".
- **Excepție, NU o contrazicere**: mecanismul `releases/latest/download/
  <nume-stabil>` (site-ul, self-updater-ul) are nevoie STRUCTURAL de un
  nume care nu se schimbă niciodată între release-uri — vezi Regula
  Domeniului & Download. Copia asta stabilă (`DataMover.pkg`,
  `GDCPluginManager.pkg`) tot trebuie publicată, DAR ALĂTURI de copia
  versionată, niciodată singură. `build_installer.sh`/`build_app.sh` din
  fiecare repo produc deja ambele — regula asta cere doar ca ambele să
  ajungă mereu pe release, nu doar cea stabilă.
- **Orice fișier construit/descărcat/trimis lui Cristi în afara acestui
  mecanism** (build local de test, artefact de CI descărcat manual,
  fișier trimis prin `SendUserFile`, copie pusă în `/tmp` pentru
  verificare) TREBUIE redenumit explicit cu versiunea înainte de a fi
  oferit — niciodată livrat cu numele generic/stabil, care are sens doar
  ca țintă a unui link fix, nu ca fișier de sine stătător pe disc.

**18. Standard UX/Arhitectură obligatoriu pentru orice aplicație desktop
NOUĂ, de la primul release (2026-08-26).** Stabilit după MediaFlow Monitor
v1.3.0 — patru cerințe care nu mai sunt opționale pentru nicio aplicație
GDC viitoare (Mac și, unde tehnologia o permite, Windows):
- **Mutare automată în `/Applications` (Mac)** — la lansare, dacă bundle-ul
  rulează în afara `/Applications` sau `~/Applications` (tipic: extras
  direct din `.zip`/Downloads, sub App Translocation), aplicația arată un
  prompt nativ ("Doriți să mutați X în Aplicații?") și, la confirmare,
  copiază bundle-ul, relansează din noua locație și mută originalul la
  Coșul de gunoi. Vezi implementarea de referință `AppMover.swift`
  (MediaFlow Monitor) — fără dependință externă (PFMoveToApplicationsFolder
  nu are un port SPM întreținut), doar `NSAlert` + `FileManager`.
- **Fereastră principală redimensionabilă liber**, cu o dimensiune minimă
  de siguranță (`minSize`/`minWidth`+`minHeight`) sub care conținutul nu
  mai e lizibil — nu ferestre cu dimensiune fixă hardcodată.
- **Selector explicit de temă System/Dark/Light**, independent de setarea
  macOS/Windows — unii clienți vor Light chiar și noaptea, alții Dark
  permanent; NU e suficient să urmezi orbește `prefers-color-scheme`/tema
  sistemului. Persistat local (`UserDefaults`/Registry), aplicat imediat
  fără repornire. Vezi `AppTheme.swift`/`ThemeManager` (MediaFlow Monitor).
- **Protocolul de semnare, notarizare, auto-update și integrare GDC
  Manager rămâne cel deja documentat în Regulile 3, 5, 6, 13, 14, 17** —
  regula asta nu introduce un protocol nou, doar reconfirmă că orice
  aplicație nouă îl respectă de la prima versiune publicată, nu "adăugat
  ulterior quando there's time".

**19. Regulă Legală & Packaging (UE/Global) (2026-08-27).**
- **Pagini Web.** Orice landing page nouă sau actualizare de site publicată
  pe `gordas.dev` (sau pe orice site GDC, inclusiv paginile de proiect
  `gordasgdc.github.io/<repo>`) TREBUIE să conțină în footer link-uri către
  `https://gordas.dev/termeni` (Termeni și Condiții),
  `https://gordas.dev/confidentialitate` (Politică de Confidențialitate
  GDPR) și, unde e relevant, `https://gordas.dev/cookie` (Cookie-uri),
  plus o notă scurtă de statut: *"gordas.dev este o platformă administrată
  de dezvoltatori independenți. Aplicațiile și resursele sunt furnizate ca
  atare (AS IS), iar susținerea proiectului se bazează pe contribuții
  opționale de sprijin și donații."* Sursa canonică a acestor 3 pagini
  legale trăiește în `gdc-plugin-manager-catalog-vendor/docs/` — orice alt
  site GDC linkuiește către ele (absolut), nu le duplică.
- **Installere (.pkg macOS / .exe Windows).** Începând cu următoarele
  versiuni/build-uri (NU retroactiv — fără rebuild al aplicațiilor deja
  publicate doar pentru asta), scripturile de instalare
  (`build_installer.sh`/`productbuild` pe Mac, `installer.iss`/Inno Setup
  pe Windows) TREBUIE să includă un pas de acceptare a licenței (License
  Agreement/SLA), bazat pe un fișier `license.rtf`/`license.txt` cu un
  extras din Termeni și Condiții (statut de proiect independent,
  licențiere legată de Machine ID, natura de donație a susținerii,
  limitarea răspunderii "as is"). Utilizatorul trebuie să apese explicit
  "Agree"/"I accept" înainte ca instalarea să se finalizeze.

  **[COMPLETARE 2026-08-27] Consimțământ obligatoriu (Consent Gate), nu
  doar text afișat.** Nu e suficient ca licența să apară — pasul trebuie
  să blocheze efectiv avansarea fără acceptare explicită:
  - **macOS (`productbuild`/Distribution.xml).** Elementul `<license
    file="License.txt" mime-type="text/plain"/>` din `Distribution.xml`
    (deja folosit de `build_installer.sh` în `gdc-plugin-manager-catalog-vendor`
    și `gdc-vault-mac`) e SUFICIENT — pagina nativă de licență a
    installer-ului macOS oferă mereu doar "Agree"/"Disagree", iar
    "Continue" nu apare fără "Agree" apăsat; nu există flag care s-o
    ocolească. Regula practică: orice `Distribution.xml` nou generat
    TREBUIE să păstreze elementul `<license>` — omiterea lui (ex. un
    installer simplificat fără pas de licență) NU e acceptabilă.
  - **Windows (Inno Setup).** Secțiunea `[Setup]` din `installer.iss`
    TREBUIE să seteze `LicenseFile=license.txt` (sau `.rtf`) — Inno Setup
    arată atunci nativ o pagină cu opțiunile radio "I accept the
    agreement" / "I do not accept", cu butonul "Next" dezactivat până la
    alegerea explicită "I accept". (Dacă vreun installer Windows ar trece
    vreodată pe NSIS în loc de Inno Setup, echivalentul e
    `!insertmacro MUI_PAGE_LICENSE` cu `MUI_LICENSEPAGE_CHECKBOX` definit,
    pentru varianta cu bifă explicită.)
  - Fișierul `license.txt`/`.rtf` folosit la acest pas trebuie să conțină
    (măcar rezumat) cele 4 puncte cheie din Termeni: statut independent
    (non-comercial), licențiere Machine ID, natura de donație a
    susținerii, garanție "as is"/limitarea răspunderii — nu doar un MIT
    License generic.

**20. Self-Updater real — obligatoriu, niciodată deschidere de browser/
GitHub (2026-08-27).** Descoperit ca bug real, repetat, pe GDC Vault (Mac
și Windows): un simplu link `releases/latest/download/...` deschis în
browser NU e suficient — utilizatorul tot ajunge pe un tab de
browser/GitHub, ceea ce Cristi consideră inacceptabil ("clientul niciodată
nu trebuie să vadă GitHub"). Orice aplicație desktop GDC (Mac/Windows) cu
proces propriu de rulat TREBUIE să implementeze un Self-Updater REAL, nu
doar un link:
- **Mac.** Descarcă `.pkg`-ul cu `URLSession.download`, cu URL-ul citit
  direct din `assets[]` al ultimului release GitHub (nu hardcodat), apoi
  îl instalează printr-un script bash elevat cu `osascript ... with
  administrator privileges` (promptul NATIV de parolă admin macOS —
  NICIODATĂ `sudo` interactiv sau Terminal vizibil), care rulează
  `installer -pkg ... -target /` și relansează aplicația singur. Vezi
  implementarea de referință `SelfUpdater.swift` (DataMover,
  `gdc-plugin-manager-catalog-vendor`, `GDCVault`).
- **Windows.** Descarcă installer-ul (`.exe`) cu `HttpClient` direct pe
  disc, redenumit cu versiunea (Regula 17), apoi îl lansează
  (`Process.Start(UseShellExecute:true)`) — fereastra NATIVĂ Inno Setup
  apare, NICIODATĂ browserul. Aplicația curentă se închide
  (`Application.Current.Shutdown()`) înainte ca userul să ajungă la pasul
  de copiere din wizard; `[Run] ... Flags: nowait postinstall
  skipifsilent` din `installer.iss` relansează aplicația după instalare —
  nu e nevoie de `AppMutex`/`CloseApplications` suplimentar. Vezi
  `SelfUpdater.cs` (`GDCPluginManagerWin`, `GDCVaultWin`).
- O fereastră minimală de progres (`UpdateProgressWindow`, text + spinner
  indeterminat) e obligatorie cât timp durează descărcarea/instalarea —
  userul nu trebuie să creadă că aplicația a înghețat.
- **WARNING permanent**: pasul efectiv de instalare (promptul de parolă
  admin pe Mac, wizardul Inno pe Windows) NU poate fi verificat automat de
  Claude — cere interacțiune fizică reală cu fereastra de sistem.
  Verificarea automată se oprește la "fișierul s-a descărcat integru,
  HTTP 200" — instalarea + relansarea efectivă TREBUIE confirmată manual,
  o dată, de Cristi, înainte ca fluxul să fie declarat complet dovedit.
- **Excepție arhitecturală, nu o abatere**: aplicații FĂRĂ proces propriu
  de rulat (plugin-uri încărcate de o gazdă terță, ex. un IOPlugin
  DaVinci Resolve) nu pot avea un "self-updater" în acest sens — rămân la
  reinstalare manuală ghidată de PDF (Regula 8), fără relansare automată.
- **Regula 13 (Update Checker) rămâne valabilă pentru DETECTAREA
  versiunii noi** (pop-up, texte, dismissal) — doar acțiunea butonului
  principal se schimbă: NU mai deschide un link, cheamă Self-Updater-ul.

**Status acest repo (2026-08-27): EXCEPTAT arhitectural, nu neimplementat.** E un IOPlugin (`.dylib`/`.dll`) încărcat de DaVinci Resolve — nu are un proces propriu de rulat pe care să-l relanseze, deci Self-Updater-ul (așa cum e definit mai sus) nu se aplică. Rămâne la reinstalare manuală ghidată de ghidul PDF trilingv deja existent (`docs/guides/`) — NU adăuga cod de auto-update aici fără să repui în discuție arhitectura de plugin.


**21. Memory & I/O Performance — obligatoriu pentru orice aplicatie care
proceseaza date/fisiere/fluxuri mari (2026-08-27).** Descoperit ca bug real
pe DataMover: un transfer de 3 TB (SSD -> HDD) umplea RAM + swap pana la
eroarea nativa macOS "Your system has run out of application memory".
Cauza radacina reala pe Mac (Swift/DataMoverMac): bucla de citire/scriere
in bucati (`FileHandle.read(upToCount:)`) rula pe un thread de fundal FARA
`autoreleasepool` per iteratie — obiectele Objective-C (`NSData`) din
spatele fiecarui `Data` bridge-uit nu se eliberau decat la finalul
INTREGULUI job (GCD creeaza un autorelease pool per bloc dispatch-uit, nu
per iteratie de bucla), deci memoria temporara se acumula neintrerupt pe
toata durata copierii unui fisier urias sau a unui transfer intreg.
Regula, valabila pentru orice aplicatie GDC (Mac/Windows) care citeste,
scrie, copiaza sau proceseaza fisiere/fluxuri de retea/date mari:

- **Zero acumulare in memorie / streaming intai.** Interzisa incarcarea
  completa a unui fisier/array/raspuns de retea mare in RAM (fara
  `Data(contentsOf:)`, `file.read()` fara argument, `shutil.copy2` pe
  fisiere mari, liste Python/array-uri Swift care colecteaza TOATE
  intrarile unei scanari mari). Orice citire/scriere/procesare foloseste
  un buffer FIX, mic (8-32 MB implicit, configurabil - vezi mai jos), care
  se citeste, se scrie si se elibereaza pe rand.
- **Backpressure.** Daca rata de citire/procesare depaseste rata de
  scriere/iesire (SSD -> HDD, retea lenta etc.), cititorul TREBUIE sa se
  incetineasca (citire sincrona, secvential cu scrierea - fara buffer de
  "read-ahead" care ar acumula date nescrise in RAM), NU sa stocheze
  diferenta in memorie/swap. Daca aplicatia are un plafon de memorie
  configurat (vezi mai jos) si il depaseste, face o pauza scurta intre
  fisiere/blocuri pana cand memoria scade, in loc sa continue orbeste.
- **UI & State Throttling.** Interzisa pastrarea in starea aplicatiei
  (RAM) a TUTUROR obiectelor procesate pentru afisare — un istoric/log de
  sute de mii de intrari intr-un `tk.Text`/`NSTextView`/array `@Published`
  neplafonat e o scurgere de memorie reala, nu doar o "UI mare". UI-ul
  primeste doar: contoare agregate (fisiere procesate, bytes transferati,
  viteza curenta) si o fereastra plafonata cu ultimele N evenimente (ex.
  200 de linii) — restul, daca trebuie pastrat, se scrie INCREMENTAL pe
  disc (CSV/log file), nu se tine intr-o lista in memorie pana la final.
  La fel, un raport final (PDF/CSV) nu tine in RAM randul fiecarui fisier
  dintr-un transfer urias doar ca sa-l scrie o singura data la sfarsit -
  CSV-ul se scrie incremental, iar un PDF/raport vizual pastreaza doar un
  esantion plafonat (plus toate erorile).
- **Scanare/recursivitate fara memorie acumulata.** La enumerarea
  recursiva a unui folder mare, nu se construieste o lista/array cu TOATE
  intrarile deodata daca sursa poate avea sute de mii/milioane de fisiere
  — se foloseste un iterator/generator sau o scriere incrementala pe disc
  (manifest), citit apoi in loturi (batch de 500-1000), ca memoria de varf
  sa ramana plafonata indiferent de dimensiunea sursei.
- **Auto-Release & eliberare explicita in bucle mari.** Pe macOS/Swift,
  orice bucla `while`/`for` care citeste/scrie/proceseaza fisiere mari pe
  un thread de fundal (`DispatchQueue.global`) foloseste `autoreleasepool { }`
  EXPLICIT per iteratie — GCD NU dreneaza automat un pool intre iteratiile
  unei bucle sincrone in interiorul unui singur bloc dispatch-uit. Pe
  Python/alte platforme, echivalentul e eliberarea explicita a
  buffer-elor/resurselor unmanaged (context manageri `with`, `close()`
  explicit) - nu te baza pe garbage collection amanata pentru resurse care
  cresc proportional cu volumul de date procesat.
- **Resource Limits & configurabilitate.** Orice aplicatie care proceseaza
  volume mari de date expune in Setari: (a) dimensiunea buffer-ului de
  citire/scriere (ex. 4/8/16/32/64 MB, implicit 8 MB), si (b) un plafon
  orientativ de memorie a aplicatiei (ex. 512 MB / 1 GB / 2 GB / 4 GB /
  fara limita), peste care se aplica backpressure-ul descris mai sus.
  Plafonul e o limita ORIENTATIVA la nivel de proces (nu un cgroup impus
  de OS) - scopul e sa incetineasca sursa cand memoria creste anormal, nu
  sa garanteze un maxim absolut.
- **Implementare de referinta**: `DataMover` — `IOSettings.swift` +
  fix-ul de `autoreleasepool` din `copyFileCancelable`/`genericHash`
  (`OffloadEngine.swift`, Mac), si `core/io_settings.py` +
  `scan_files_streaming`/`iter_manifest_batches` + raport CSV incremental
  (`core/offload_engine.py`, Windows/Python). Orice aplicatie GDC noua sau
  modificata care atinge fisiere/fluxuri mari respecta acest standard de
  la urmatoarea ei actualizare, nu doar DataMover.

**Status acest repo (2026-08-28, verificat): EXCEPTAT ARHITECTURAL, motiv DIFERIT de Regula 20.** Auditat la cererea lui Cristi — `ffmpeg_encoder.cpp` encodeaza cadru-cu-cadru prin libavcodec (`av_frame_alloc`/`av_frame_get_buffer`, pachete flush-uite unul cate unul), deja streaming prin design — nu incarca niciodata fisierul/timeline-ul intreg in memorie. Tunabilul de memorie relevant aici e `rc_buffer_size` si celelalte setari de rate-control ale encoder-ului FFmpeg, NU un "buffer de citire in MB" generic ca la copierea de fisiere brute (DataMover) — cele doua nu sunt acelasi tip de problema, desi ambele sunt "memorie la fisiere mari".

**22. `PlatformTarget` explicit obligatoriu pentru orice proiect .NET/WPF cu
pachete NuGet native (2026-08-28).** Gasit pe DataMover (client WPF): un
`.csproj` implicit "Any CPU" ruleaza, pe host-ul Windows al lui Cristi
(Parallels pe Mac Apple Silicon), ca `win-arm64` - iar biblioteci cu
binare native (QuestPDF/Skia, si potential altele similare) NU au build
pentru arhitectura asta, cazand tacut cu `DllNotFoundException`/
`TypeInitializationException` doar la runtime, niciodata la `dotnet build`.
Orice `.csproj` nou (sau existent, la prima dependinta nativa adaugata) din
`GDCVaultWin`/`GDCPluginManagerWin`/`DataMover`/orice client Windows viitor
seteaza explicit `<PlatformTarget>x64</PlatformTarget>` - Windows 11 ARM
ruleaza procesul x64 prin emulatie nativa a OS-ului, deci functioneaza
identic pe Windows x64 real si pe ARM64/Parallels. Nu te baza pe "Any CPU"
doar pentru ca merge la compilare.

**23. Garda obligatorie impotriva `dist/` detinut de root, in orice
`build_app.sh` Mac (2026-08-28).** Bug real, repetat de mai multe ori pe
DataMover in aceeasi sesiune (cauza exacta neconfirmata - posibil o
instalare de test cu `sudo installer -pkg ... -target /` care a atins
accidental folderul local): `dist/<App>.app` ramas detinut de `root:wheel`
dintr-un build anterior face ca `rm -rf "dist"` de la inceputul scriptului
sa esueze partial, tacut, cu o gramada de "Permission denied" greu de
gasit in mijlocul unui log lung. Orice `build_app.sh` din ecosistem
(DataMover, GDCVault, CursorPro, gdc-plugin-manager-catalog-vendor, orice
build Mac viitor) verifica ACEST lucru explicit INAINTE de `rm -rf`, cu un
mesaj clar si actionabil (`sudo rm -rf $(pwd)/dist`, de rulat manual O
SINGURA DATA de Cristi - Claude nu poate rula `sudo`), in loc sa lase
`rm -rf` sa esueze criptic:
\`\`\`bash
if [ -d "dist" ] && ! [ -w "dist" ] || find dist -maxdepth 2 -user root -print -quit 2>/dev/null | grep -q .; then
    echo "EROARE: 'dist/' contine fisiere detinute de root. Ruleaza manual:" >&2
    echo "    sudo rm -rf \$(pwd)/dist" >&2
    exit 1
fi
\`\`\`
Practic, inaintea oricarui `release.sh`: `ls -la mac-native/dist` (listare
COMPLETA, nu trunchiata cu `head`) - o listare trunchiata poate rata
`<App>.app` daca sorteaza dupa alte fisiere (`.pkg`/`.zip`), dand o
verificare falsa de "curat".

**24. Standard UI obligatoriu: Setare explicită "Mărime Text" + Layout
robust la redimensionare (2026-08-29).** Completare la Regula 18 — găsit pe
GDC Plugin Manager (Mac): un bug real de layout la resize RAPID al
ferestrei (blocul de profil/footer din sidebar rămânea temporar suprapus
peste conținutul de deasupra) cauzat de `.safeAreaInset(edge:)` atașat
DIRECT pe un `List`/`ScrollView` — la resize rapid pe macOS, content-insetul
intern al listei nu se resincronizează mereu instant cu safe-area-ul
suprapus (bug de sincronizare AppKit/SwiftUI, nu o presupunere). Regulă
practică, valabilă pentru orice fereastră GDC (Mac/Windows) cu o zonă
fixă (footer/header) lângă o listă/grid scrollabilă:
- **Niciodată `.safeAreaInset` direct pe un `List`/`ScrollView` pentru un
  element care trebuie să rămână mereu vizibil și nesuprapus** — pune
  lista și elementul fix ca FRAȚI într-un `VStack`/`Grid` simplu (cu
  `Divider()` între ele, dacă are sens vizual). Layout-ul calculat direct
  de container e mereu sincron, cadru cu cadru, spre deosebire de
  safe-area-ul suprapus peste scroll.
- **Fereastra principală rămâne liber redimensionabilă** (Regula 18), dar
  cu `minWidth`/`minHeight` verificate să nu lase conținutul ilizibil sub
  acel prag — nu doar prezente, ci suficient de generoase pentru sidebar-ul
  cu cele mai multe secțiuni al aplicației respective.
- **Setare explicită "Mărime Text" (Mic/Normal/Mare/Foarte mare) e acum
  standard**, alături de selectorul de temă din Regula 18 — pe SwiftUI/Mac,
  prin infrastructura NATIVĂ de accesibilitate (`dynamicTypeSize()` aplicat
  la rădăcina ferestrei principale, NU un multiplicator brut de font — text
  semantic (`.font(.headline)`/`.caption`/etc) + `dynamicTypeSize` garantează
  reflow corect, spre deosebire de o scalare custom care poate tăia conținut
  în frame-uri fixe). Pe Windows/WPF, echivalentul e un `FontSizeConverter`/
  resursă de `FontSize` global legată de o setare persistată (`Registry`/JSON),
  aplicată la nivelul `Application.Resources`. Persistat local, aplicat
  imediat, fără repornire — la fel ca selectorul de temă.
- Referință de implementare: `TextScalePreference`/`TextScaleManager`
  (`Sources/GDCPluginManagerCore/AppTheme.swift`, `gdc-plugin-manager-catalog-vendor`)
  + restructurarea `NavigationSplitView`/`List` din `ContentView.swift`
  (același repo) — port-ul pe orice altă aplicație GDC (Mac/Windows) cu
  panou lateral fix trebuie verificat la fel pentru acest pattern.

**25. `CHANGELOG.md` obligatoriu la fiecare bump de versiune + Log de
Diagnostic permanent, nu print-uri temporare (2026-08-29).**
- **`CHANGELOG.md`** (rădăcina fiecărui repo) — separat de jurnalul tehnic
  detaliat din acest fișier (CLAUDE.md păstrează deciziile/motivele/
  pitfall-urile complete; `CHANGELOG.md` e un rezumat SCURT, orientat spre
  ce s-a schimbat pentru utilizator, o intrare per versiune/dată, ușor de
  scanat rapid fără să citești tot jurnalul). Actualizează-l în ACELAȘI
  commit ca bump-ul de versiune — la fel de obligatoriu ca bump-ul însuși.
  Dacă repo-ul nu are încă `CHANGELOG.md`, creează-l la prima actualizare
  viitoare (nu aștepta o cerere explicită).
- **Log de Diagnostic PERMANENT** (`DiagnosticLog.write(tag:, message:)` —
  Mac: `GDCPluginManagerCore/DiagnosticLog.swift`, `%TEMP%/gdcpm-crash.log`;
  Windows: `DiagnosticLog.cs`, echivalent) — pentru orice flux nou cu
  potențial de eșec silențios (fetch de rețea, decodare, publicare/commit
  git, încărcare de imagine/resursă asincronă): adaugă apeluri de log DE LA
  ÎNCEPUT, nu abia când apare un bug de investigat. Motiv real, găsit chiar
  în această sesiune: bug-ul cu filigranul sezonier care nu se încărca
  niciodată a fost diagnosticat DOAR după ce am adăugat manual print-uri
  temporare și am rulat aplicația din Terminal — cu logul permanent deja
  acolo, diagnosticul ar fi durat un fișier citit, nu o sesiune de
  reproducere manuală. Un singur fișier de log, comun tuturor componentelor
  aceleiași aplicații (Client + Furnizor, dacă există) — userul trimite UN
  fișier, nu trebuie să știe care componentă a scris eroarea.

**26. Instalare pas-cu-pas (buton roșu/verde per componentă) + Panou
„Terminal Live” obligatoriu pentru orice comandă externă (2026-08-30).**
Stabilit după Master Control Studio Pro (Mac + Windows) — două cerințe
care devin standard pentru orice aplicație GDC nouă sau modificată, de la
următoarea ei actualizare:
- **Niciodată un buton „Instalează tot ce lipsește"/instalare în masă
  fără control explicit.** Orice componentă instalabilă (dependență,
  pachet, plugin) are propriul buton de acțiune, colorat după stare:
  **roșu** = neinstalat/apăsabil, **verde** = instalat (dezactivat, doar
  informativ). Motiv direct de la Cristi: o instalare în masă, silențioasă,
  a mai multor pachete deodată poate bloca sistemul clientului — pas cu
  pas, userul vede exact ce se instalează și când.
- **Panou „Terminal Live" obligatoriu** pentru orice acțiune care rulează
  o comandă externă (instalare pachet, ștergere fișiere/cache, montare
  cloud, orice `Shell.run`/`Process.Start` cu potențial de durată sau
  eșec): un panou tip terminal (fundal închis, text monospace, auto-scroll)
  afișează LINIE CU LINIE ce se execută și rezultatul — niciodată doar un
  text static „Se instalează…"/"✔ Gata" fără detalii. Motiv real, găsit
  2026-08-30: ștergerea de cache pe Windows eșua silențios pe primul fișier
  blocat (catch înfășura toată bucla, nu fiecare fișier), iar userul nu
  avea NICIO indicație că ceva nu a mers — cu panoul de-al doilea rând, nu
  doar bug-ul devine vizibil imediat, ci și comportamentul normal (ce se
  întâmplă „în fundal") devine transparent pentru client.
- **Implementare de referință**: `TerminalLogView.swift` (SwiftUI, Mac) +
  `Controls/TerminalLogView.xaml`/`.cs` (WPF, Windows) — ambele din
  `MacMasterControlPro`/`MacMasterControlProWin`; `DependenciesModuleView.swift`/
  `DependenciesPage.xaml.cs` din același repo arată tiparul de buton
  roșu/verde per element. Portul pe orice altă aplicație GDC (Mac/Windows)
  cu un flux de instalare/dependențe sau operații pe fișiere/rețea trebuie
  verificat la fel pentru acest pattern.
- **Regula 25 (Log de Diagnostic permanent) rămâne complementară, nu
  înlocuită**: `DiagnosticLog` scrie pe disc pentru diagnosticare de la
  distanță (Cristi citește fișierul), panoul „Terminal Live" arată userul
  ÎN TIMP REAL ce se întâmplă, direct în UI — cele două servesc scopuri
  diferite și rămân ambele obligatorii.

**27. Preț dinamic ("Pricing Manager"), fără recompilare (2026-08-30).**
Stabilit după un audit real: prețul de donație al fiecărei aplicații era
hardcodat direct în cod (`Localization.swift`/`.cs`, text WhatsApp
pre-completat) — o simplă ofertă de Black Friday necesita recompilarea +
resemnarea + republicarea FIECĂREI aplicații (12 repo-uri) doar ca să
schimbi o cifră afișată. Devine standard pentru orice aplicație GDC
nouă/modificată, de la următoarea ei actualizare:
- **`docs/pricing.json`** (nou, `gdc-plugin-manager-catalog-vendor`,
  servit static la `https://gordas.dev/pricing.json`) — sursa canonică a
  prețurilor, per `productID`: `basePrice` + un `promoSchedule` (LISTĂ de
  ferestre de ofertă programate din timp — preț, etichetă, interval de
  timp, `showCountdown` opțional pentru un countdown live în UI). NU o
  singură ofertă on/off — Cristi poate programa dinainte mai multe
  perioade succesive (lună curentă, Black Friday, Crăciun), aplicația
  alege singură fereastra activă la momentul respectiv.
- **Furnizor — panoul "Prețuri & Oferte"** (`PricingManagerView.swift`,
  `gdc-plugin-manager-catalog-vendor`) — editează prețul de bază +
  programul de oferte per produs, "Publică" face `git pull` → scrie
  `docs/pricing.json` → `commit`+`push` (reutilizează `GitOps` deja
  existent) — live pe toate aplicațiile în câteva minute, FĂRĂ nicio
  recompilare.
- **`PricingChecker`** (portat identic per aplicație client, după modelul
  `UpdateChecker`/`update.json`) — fetch la lansare (+ manual, la
  deschiderea ecranului de activare), calculează prețul efectiv (fereastra
  activă din `promoSchedule`, altfel `basePrice`). **Fail-open, ca
  RevocationCheck (Regula 12)**: fără conexiune sau `productID` lipsă din
  `pricing.json`, se folosește prețul hardcodat existent în cod ca
  fallback — niciodată un ecran de donație gol/eronat.
- Orice loc care afișează prețul (ecranul de activare/donație, mesajul
  WhatsApp pre-completat, landing page-ul aplicației) citește prin acest
  checker, nu o valoare hardcodată direct.
- **Status (2026-08-30): IMPLEMENTAT integral în Furnizor + pilot complet
  în DataMover (Mac)** — `PricingChecker.swift`, `ActivationSheet.swift`.
  Portul pe DataMover (Windows) și pe restul aplicațiilor din ecosistem
  (CursorPro, GDCVault, CGConvertor, MediaFlow Monitor, Master Control
  Studio Pro) rămâne TODO, de făcut incremental — fiecare aplicație
  atinsă de acum înainte trebuie să adopte acest pattern, nu doar cele
  menționate aici.

**28. Auditul licenței active NU e opțional la nicio modificare de
licențiere (2026-08-30).** Descoperit direct din acest bug: DataMover avea
`isUnlocked`/`IsUnlocked` calculat corect (`isLicensed || isTrialActive`)
dar NEFOLOSIT nicăieri — proba nu bloca NIMIC, nici măcar după expirare,
pe ambele platforme, de la prima implementare. Bug-ul a stat nedescoperit
mult timp fiindcă nimeni nu a verificat explicit "acest câmp e doar
calculat, sau chiar oprește o acțiune reală?". Regulă practică: la orice
atingere a fluxului de licențiere/probă al unei aplicații GDC (Mac/
Windows), verifică explicit — cu `grep`, nu presupunere — că orice câmp
gen `isUnlocked`/`isLicensed`/`isTrialActive` e efectiv REFERENȚIAT
într-un `guard`/`if` care blochează o acțiune reală (scriere pe disc,
pornire transfer, aplicare modificare), nu doar afișat într-un banner
informativ. Un banner "X zile rămase" fără nicio consecință reală nu e
gating, e doar UI. **Audit 2026-08-30 (rezultat)**: CursorPro, GDCVault,
CGConvertor, Master Control Studio Pro — verificate, gating real prezent.
DataMover — bug real, reparat (plafon de 2 GB per transfer în versiunea
neactivată, vezi Etapa 2026-08-30 (2) din secțiunea Partea 2).
`gdc-production-manager`/`gdc-resolve-encoder` — arhitectură diferită
(backend/C++), nu acoperite de acest audit, de verificat separat.

**29. Zero informație internă în orice loc PUBLIC (release notes GitHub,
fișiere comise într-un repo public, commit messages vizibile) (2026-08-31).**
Bug real, găsit de Cristi live pe `gdc-plugin-manager` (v1.21.0): descrierea
publică a unui GitHub Release conținea citate directe ("Cerință explicită a
lui Cristi: ...") și explicații de cauză/debugging ("Raportat de Cristi: ...",
"Cauza reală: ..."), iar `MacMasterControlPro` avea un fișier
`GHID_INTERN_ONBOARDING_GOOGLE_DRIVE.md` — destinat EXCLUSIV lui Cristi —
comis la rădăcina unui repo PUBLIC, vizibil oricui. Motivul dat de Cristi:
"clientii nu trebuie sa vada mesajele explicative a dezvoltarii aplicatiei,
creeaza vulnerabilitati de securitate" — expune numele lui, fluxul de
raportare a bug-urilor, detalii de implementare interne (nume de fișiere,
clase, cauze tehnice) unei audiențe publice necunoscute.
- **Orice text destinat unui `gh release create`/`gh release edit` pe un
  repo PUBLIC e scris DIN START ca notă de lansare orientată spre client**:
  ce e nou / ce s-a reparat, în limbaj simplu, FĂRĂ nume proprii, FĂRĂ
  citate din conversația cu Cristi, FĂRĂ "cauza reală"/explicații de
  debugging, FĂRĂ nume de fișiere/clase/funcții din cod. Jurnalul tehnic
  complet (cu tot context-ul de mai sus) rămâne EXCLUSIV în `CLAUDE.md`/
  `CHANGELOG.md` din repo — acelea nu apar niciodată ca body de release.
- **Niciun fișier "intern"/"doar pentru Cristi" nu se comite la rădăcina
  (sau oriunde altundeva) unui repo cu `isPrivate: false`.** Dacă un
  document e cu adevărat intern (proceduri de admin, secrete de proces,
  chei/target-uri de whitelisting etc.), trăiește DOAR local, adăugat
  explicit în `.gitignore` — niciodată împins pe un remote public. Dacă
  un asemenea fișier a fost deja comis pe un repo public, se elimină din
  working tree + `.gitignore` imediat (istoricul git rămâne, ca la orice
  secret comis anterior — semnalat explicit lui Cristi, nu doar curățat
  tacit, exact ca la Regula 2).
- **Verificare obligatorie înainte de orice `gh release create`/`edit`**:
  recitește textul notelor ca și cum ai fi un client care nu știe nimic
  despre proces — orice propoziție care ar suna ciudat/nepotrivit unui
  necunoscut (nume, citate, cauze tehnice de debugging) se rescrie sau se
  elimină înainte de publicare, nu după ce cineva o semnalează.
- **Audit retroactiv (2026-08-31)**: curățate manual release notes publice
  pentru `gdc-plugin-manager` (v1.21.0, v1.20.1), `mac-master-control-pro`
  (v2.9.0, v2.8.0), `mac-master-control-pro-win` (v1.10.0),
  `MediaFlow-Monitor` (v1.0.0/v1.0.1) — restul release-urilor mai vechi din
  ecosistem rămân de verificat incremental, nu toate dintr-o dată.

**30. Zero cod "impur" sau nelalocul lui — orice implementare TREBUIE
finalizată complet, nu doar compilată (2026-09-03).** Cerință explicită de
la Cristi, după un incident real: un fix scris în cod dar nepropagat peste
tot unde era nevoie (versiune, `update.json`, ambele platforme, ambele
aplicații) a lăsat sistemul într-o stare pe jumătate — "să nu rămână nimic
inpur și nelalocul lui, să se implementeze tot ce am actualizat și am
creat, să nu mai avem probleme". Regulă practică, obligatorie la orice
schimbare de cod:
- Orice constantă/valoare copiată dintr-un alt fișier/repo (chei, ID-uri,
  praguri, URL-uri) se verifică ACTIV cu `grep`, nu se presupune corectă
  doar pentru că a fost copiată — un audit se oprește abia când TOATE
  aparițiile au fost verificate, nu doar cea raportată inițial.
- O funcționalitate nouă/modificată se declară "gata" abia după ce
  TOATE piesele ei sunt implementate și verificate — cod, rebuild+reinstall
  (Regula 0), versiune sincronizată peste tot unde trebuie (Regula 14),
  paritate Mac/Windows dacă aplică (regula de mai jos), `CHANGELOG.md`
  (Regula 25). O piesă lăsată "pentru mai târziu" se spune EXPLICIT, nu se
  ascunde într-un răspuns care sună ca "gata".
- Orice implementare/îmbunătățire nouă a acestei Părți 1 se scrie DIN
  START în `CLAUDE.md`-ul TUTUROR proiectelor din `~/Developer/` (Regula
  11) — nu doar în repo-ul unde a pornit discuția.

**31. Paritate Mac/Windows imediată, în aceeași sesiune (2026-09-03).**
Completare la Regula 30: orice schimbare de cod livrată pe Mac care are un
echivalent Windows în ecosistem (și invers) se portează 1:1 ÎN ACEEAȘI
SESIUNE, fără să aștepți o cerere separată de la Cristi — portul e parte
integrantă a schimbării, nu un TODO ulterior. Dacă portul chiar nu poate
fi făcut acum (acces la mediul Windows indisponibil, testare reală
imposibilă), se spune EXPLICIT ce lipsește și de ce, marcat clar în
`CHANGELOG.md` ca "TODO paritate Windows/Mac" (Regula existentă de
documentație) — nu se lasă nemenționat.

## [PARTEA 2: SPECIFICAȚII TEHNICE PROIECT]

## REGULĂ PERMANENTĂ: Locația proiectului pe disc (2026-08-25)
Acest repo trăiește în **`~/Developer/gdc-resolve-encoder`**, NU în
`~/Downloads`. Motiv: `~/Downloads` e curățat automat de CleanMyMac/Hazel
pe acest Mac.

## Jurnal tehnic

**2026-09-04 — v1.4.0: optimizare cerută de Cristi ("calitate slabă,
viteză mică, crash-uri, opțiuni lipsă") + instalator Windows.** Cerere
venită cu SDK-ul oficial Blackmagic (`CodecPlugin.zip`, exemplul
`x264_encoder_plugin`) și link-urile VideoLAN x264/x265 ca referință
explicită. Comparat codul nostru cu exemplul oficial — găsite cauze
concrete, nu presupuneri:
- `m_pCtx->gop_size` era hardcodat la 12 cadre (fix la orice frame
  rate) — acum calculat din `HostCodecConfigCommon::GetFrameRateNum/
  Den()` (deja disponibil, doar nefolosit pentru asta), cu 2 secunde
  implicit, expus ca slider `gdc_keyframe_interval`.
- `color_primaries`/`color_trc`/`colorspace` nu erau setate NICIODATĂ pe
  `AVCodecContext` (doar `color_range`) — acum setate explicit (BT.709
  implicit, BT.2020 pentru variantele 10-bit sau dacă `clrPrimaries`
  citit de la host indică asta). Adăugat `IPropertyProvider::GetINT16`
  (`wrapper/host_api.h`/`.cpp`) — nu exista, doar GetINT32/UINT8/INT64/
  Double/String — mecanic, oglindă exactă a `GetINT32`. **Notă onestă**:
  maparea `clrPrimaries` → `AVColorPrimaries` presupune convenția
  standard ISO/IEC 23001-8 (CICP) — NU confirmată direct cu un export
  real din Resolve, doar cea mai probabilă interpretare dat fiind
  numele proprietății; `color_trc`/`colorspace` sunt derivate dintr-o
  mapare mică, explicită (NU o reinterpretare brută a aceleiași valori
  ca trei enum-uri diferite — greșeală pe care am scris-o inițial și am
  corectat-o înainte de commit, verificată cu grep, nu presupunere).
- Profilul „high422", oferit în UI pentru variantele H.264 8-bit, nu
  corespundea NICIUNUI `EncoderVariant` real (toate sunt 4:2:0/NV12) —
  candidat plauzibil pentru eșecuri de `avcodec_open2` raportate ca
  "nu se încarcă stabil". Eliminat din listă (în ambele locuri:
  `s_GetEncoderSettings` ȘI `OpenCodec` — verificat cu grep că nu mai
  rămâne nicio referință).
- Adăugat: control **Level** (`gdc_level`, dropdown Auto + 3.0-5.2),
  **thread_count explicit** (`std::thread::hardware_concurrency()`,
  plafonat la 32), și câmp de **„Parametri avansați"**
  (`gdc_advanced_params`, trimis ca `x264-params`/`x265-params` prin
  `av_dict_set` — exact modelul MainConcept de acces expert, fără să
  cablăm un slider nou pentru fiecare opțiune x264/x265 posibilă).
- **2-pass (multi-pass) ABR — identificat ca feature real lipsă, prezent
  chiar în exemplul oficial Blackmagic** (`x264_num_passes`,
  `x264_param_apply_fastfirstpass`) — infrastructura de host EXISTĂ deja
  în wrapper-ul nostru, neconectată (`IsNeedNextPass()` în
  `wrapper/plugin_api.h`, `pIOPropMultiPass` în `IOPluginProps.h`).
  **NEIMPLEMENTAT în acest pas, explicit** — cea mai mare bucată de cod
  nouă din tot planul, amânată deliberat la o sesiune viitoare, ca restul
  fix-urilor (mai mici, mai sigure) să nu aștepte după ea. Nu ascuns —
  rămâne TODO documentat aici.
- **Instalator Windows nou** (`install.ps1` + `install.bat`, rădăcina
  repo-ului) — nu exista NIMIC înainte (userul copia manual folderul
  bundle). Oglindă funcțională a `install.sh` (Mac, deja corect):
  găsește bundle-ul, verifică structura, copiază în
  `%ProgramData%\Blackmagic Design\DaVinci Resolve\Support\IOPlugins\`,
  cu re-lansare automată elevată (`Start-Process -Verb RunAs`) dacă
  scrierea eșuează din lipsă de drepturi — Standard GDC de fallback
  privilegiat, nu doar raportare de eroare. `install.bat` mic adăugat
  ca wrapper dublu-clic (userul obișnuit nu vrea să facă click-dreapta →
  "Run with PowerShell" pe un `.ps1`). `.github/workflows/build.yml`
  actualizat să includă ambele fișiere în
  `gdc-resolve-encoder-windows-x64.zip`, lângă bundle+PDF-uri deja
  incluse (Mac avea deja `install.sh` inclus în zip-ul lui, neschimbat).
- Verificat: `cmake --build` complet, curat (0 erori/avertismente) pe
  Mac direct. Windows/Linux verificate prin CI (`.github/workflows/
  build.yml`, rulează automat la push) — **NU verificat prin export
  real în DaVinci Resolve** (nu am acces la Resolve din acest mediu);
  comportamentul real (calitate vizuală, viteză, `install.ps1` rulat
  efectiv pe un Windows real, inclusiv fallback-ul de elevare) rămâne de
  confirmat de Cristi.
- Versiune: acest plugin nu ține un număr de versiune în cod (distribuit
  prin tag-uri GitHub Release, vezi nota arhitecturală de mai jos) —
  următorul tag e `v1.4.0` (MINOR — opțiuni noi vizibile: Level,
  Keyframe Interval, Parametri avansați, instalator Windows).

## NOTĂ ARHITECTURALĂ: Directiva Supremă de release NU se aplică 1:1 aici
Acesta e un plugin DaVinci Resolve (OFX), NU o aplicație standalone cu
propriul site/UI/meniu — nu are fereastră About, nu are meniu propriu de
verificare-actualizări, și nu se distribuie printr-un site propriu. E
livrat ca produs în catalogul GDC Plugin Manager (vezi
`gdc-plugin-manager/docs/catalog.json`) — versiunea, verificarea de
actualizări și pachetul de instalare sunt responsabilitatea Manager-ului
care îl instalează, nu ale acestui repo direct. Licențierea (Ed25519,
Machine ID) rămâne totuși sincronizată cu `LicenseCore.swift`/`.cs`/`.py` —
vezi `gdc-plugin-manager/CLAUDE.md`.

**2026-09-04 — Linux scos din lansări, începând cu v1.5.0.** Cerut explicit
de Cristi ("începand cu urmatoarea actualizare scoatem varianta de
Linux"). Făcut: jobul `build-linux` eliminat COMPLET din
`.github/workflows/build.yml` (nu doar dezactivat — cod mort), `needs:`/
lista de fișiere a jobului `release` actualizate să nu mai aștepte/atașeze
asset-ul Linux, `README.md`/`.en.md`/`.es.md` curățate de toate mențiunile
Linux (tabele de codecuri, secțiune de instalare, cerințe, diagrama
bundle-ului, comanda de build din sursă) — verificat cu `grep -i linux`,
zero rezultate rămase în toate cele 3 README-uri. **NEFĂCUT încă, TODO
explicit**: `docs/index.html` (pagina de prezentare, `gordas.dev`-style)
încă are un tab întreg „Linux" în secțiunea de instalare, un buton de
download către `gdc-resolve-encoder-linux-x64.zip` (care va da 404 la
prima lansare fără acel asset), rânduri de tabel și texte i18n (RO/EN/ES)
menționând Linux — pagină HTML/JS de o singură bucată, nu am citit-o
integral și nu am editat-o acum ca să nu risc s-o stric fără verificare
vizuală reală. De făcut la următoarea atingere a acestui repo, înainte de
`v1.5.0`.

**2026-09-04 — v1.4.1: BUG STRUCTURAL REAL găsit la testare — FFmpeg
SONAME mismatch — + instalator .pkg semnat/notarizat.** Cristi a instalat
v1.4.0 (Mac) și pluginul nu apărea deloc în lista de codecuri din
Resolve, deși bundle-ul era prezent corect în folderul IOPlugins. Diagnoză
directă pe mașina lui (`otool -L`, `xattr`, `codesign -dv`, versiune chip,
FFmpeg instalat): pluginul PUBLICAT (construit de CI, `macos-14` runner,
`brew install ffmpeg` proaspăt la fiecare build) cerea
`libavcodec.62.dylib`/`libavutil.60.dylib`/`libswscale.9.dylib`, dar
FFmpeg-ul de pe mașina lui (Homebrew, la zi) avea DOAR
`.63`/`.61`/`.10` — SONAME-uri diferite, deci `dlopen` eșuează SILENȚIOS
la încărcarea plugin-ului de către Resolve (fără nicio eroare vizibilă în
UI). **Cauză structurală, nu doar o instalare veche**: pluginul se leagă
DINAMIC la calea absolută Homebrew a FFmpeg-ului de PE MAȘINA DE
COMPILARE — orice discrepanță de versiune între mașina CI/build și mașina
utilizatorului (extrem de probabilă, Homebrew updatează ffmpeg des) rupe
încărcarea, silențios, fără avertisment. Foarte plauzibil să fi fost un
contributor real la "crash-uri / nu se încarcă stabil" din cererea
inițială a lui Cristi — mai degrabă decât (sau pe lângă) profilul
"high422" reparat în v1.4.0.

**NEREZOLVAT DEFINITIV — TODO real, explicit, pentru sesiunea următoare**:
soluția corectă e fie (a) legarea FFmpeg static la compilare (elimină
complet dependența de runtime), fie (b) bundling-ul dylib-urilor FFmpeg +
TOATE dependințele lor tranzitive (x264, x265, etc.) direct în bundle,
cu `install_name_tool`/`@loader_path` rescriere de căi — exact ce face
deja Windows (DLL-urile FFmpeg sunt incluse direct în arhivă, vezi
`.github/workflows/build.yml`). Un instrument ca `dylibbundler` ar face
asta corect și complet (recursiv); NU încercat acum — bundling manual,
incomplet, ar fi mutat problema un nivel mai jos (dependințele
TRANZITIVE ale libavcodec însuși) fără s-o rezolve cu-adevărat.

**Fix practic, imediat, aplicat**: `build_installer.sh` (NOU) — compilează
plugin-ul LOCAL, pe mașina curentă (deci garantat potrivit cu FFmpeg-ul
ei), îl semnează cu `APPLE_SIGN_IDENTITY_APP` (cert deja existent în
`~/Developer/Certificates/`, `entitlements.plist` copiat neschimbat din
`codesigning/` — `com.apple.security.cs.disable-library-validation` e
critic aici, altfel Hardened Runtime ar respinge dylib-urile Homebrew
nesemnate de noi), îl împachetează într-un `.pkg` (`pkgbuild` +
`productbuild`, payload direct la
`/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins/`,
`installer/scripts/preinstall` curăță o instalare veche, `installer/
License.txt` nou — Regula 19, pas de licență Agree/Disagree obligatoriu),
apoi semnează+notarizează+staplează pachetul final
(`codesigning/sign-and-notarize.sh pkg`, folder copiat NESCHIMBAT din
`GDCVault`). **Testat efectiv, cu succes complet**: `spctl -a -vv -t
install` → `accepted, source=Notarized Developer ID`; notarizare Apple
reușită (`status: Accepted`); `pkgutil --payload-files` confirmă
destinația corectă. Trimis lui Cristi ca fișier, de instalat prin
dublu-clic — cerut explicit ("vreau instalare tip pkg", "sa nu rulez eu
in terminal"). `install.sh` (Terminal) rămâne disponibil ca alternativă
manuală, dar `.pkg`-ul e acum calea principală recomandată pe Mac.
Versiune 1.4.0 → 1.4.1 (PATCH — fix real de încărcare + instalator nou,
nicio schimbare de funcționalitate de encodare).

**2026-09-05 — v1.4.2: TODO-ul „NEREZOLVAT DEFINITIV" de mai sus, rezolvat
efectiv — bundling FFmpeg + toate dependințele tranzitive, cu
`dylibbundler`.** Opțiunea (b) din nota de mai sus, aleasă (statică ar fi
însemnat recompilarea FFmpeg din surse, mult mai fragil de întreținut).
- **`bundle_ffmpeg_mac.sh`** (NOU, rădăcina repo-ului) — o singură sursă de
  adevăr, apelată identic din `build_installer.sh` (local, `.pkg`
  notarizat) ȘI din `.github/workflows/build.yml` (CI, zip) — Regula 30,
  zero cod duplicat care poate diverge. Rulează `dylibbundler -ns -cd -b`
  pe binarul `.dvcp` cu `-p @loader_path/../Frameworks/`, copiind
  `libavcodec`/`libavutil`/`libswscale`/`libswresample` ȘI toate
  dependințele lor tranzitive reale (verificate la rulare pe acest Mac:
  `libx264`, `libx265`, `libvpx`, `libdav1d`, `libSvtAv1Enc`, `libopus`,
  `libmp3lame`, `libmpg123`, `liblzma`, `libssl`, `libcrypto` — 15
  biblioteci în total) direct în `Contents/Frameworks/` al bundle-ului.
  `-ns` dezactivează semnarea ad-hoc automată a lui `dylibbundler` — script-ul
  semnează el însuși fiecare dylib, cu `APPLE_SIGN_IDENTITY_APP` (Developer
  ID real, necesar pentru notarizare) dacă e setat în mediu, altfel ad-hoc
  (fluxul CI/zip nesemnat, neschimbat). Verificare automată inclusă în
  script: `otool -L` pe binar ȘI pe fiecare dylib copiat, eșuează exit 1
  dacă mai rămâne vreo cale absolută `/opt/homebrew`/`/usr/local/opt`.
- **`build_installer.sh`** — reordonat: bundling-ul FFmpeg rulează ACUM
  între copierea binarului brut în bundle și semnarea finală a binarului
  principal (`dylibbundler` rescrie load commands, ceea ce invalidează
  orice semnătură anterioară — semnarea trebuie să vină ultima).
- **CI (`build.yml`, jobul `build-macos`)** — adăugat `brew install
  dylibbundler` lângă `cmake`/`pkg-config`/`ffmpeg` deja existente, plus
  apelul la `bundle_ffmpeg_mac.sh` + o semnare ad-hoc a binarului principal
  (înainte nesemnat complet) imediat după compilare, înainte de zip. Zip-ul
  de pe GitHub Releases e acum la fel de self-contained ca `.pkg`-ul local.
- **`install.sh`** — eliminat complet pasul de verificare/instalare
  Homebrew+FFmpeg (nu mai e nevoie de el structural).
- **`README.md`/`.en.md`/`.es.md`** — actualizate să reflecte că FFmpeg nu
  mai trebuie instalat separat pe Mac (secțiunea "Despre FFmpeg", pașii de
  instalare, lista de Cerințe). Secțiunea de compilare din surse
  (`brew install cmake pkg-config ffmpeg`) rămâne neschimbată — e nevoie de
  headers FFmpeg la COMPILARE, distinct de dependința de RUNTIME eliminată
  aici.
- **`docs/index.html`** (RO/EN/ES, i18n) — rândul din secțiunea Cerințe
  care cerea `brew install ffmpeg` pe Mac, înlocuit cu confirmarea că nu
  mai e nevoie de nimic în plus.
- **NEFĂCUT, TODO explicit**: cele 3 ghiduri PDF trilingve
  (`docs/guides/GDC_Resolve_Encoder_Ghid_RO.pdf` etc.) probabil mai
  menționează pasul Homebrew/FFmpeg (Regula 8(b)) — sunt fișiere binare
  statice, fără script generator în acest repo, NEVERIFICATE și
  NEACTUALIZATE acum. De revizuit/regenerat la următoarea atingere a
  documentației acestui repo.
- **Verificat real, nu presupus**: `cmake --build` curat (0 erori) pe
  această mașină; `./bundle_ffmpeg_mac.sh` rulat direct pe binarul
  compilat local — output confirmă 15 dylib-uri copiate, verificarea
  internă `otool -L` a trecut (zero căi Homebrew rămase). Test funcțional
  real de încărcare: `ctypes.CDLL(...)` (Python, echivalent cu `dlopen`
  folosit de Resolve) a reușit ÎNAINTE și DUPĂ semnarea binarului
  principal; `DYLD_PRINT_LIBRARIES=1` confirmă că TOATE cele 15
  dependințe se încarcă din `Contents/Frameworks/` al bundle-ului, ZERO
  referințe la `/opt/homebrew` — dovadă directă că bug-ul de SONAME
  mismatch (v1.4.1) nu se mai poate reproduce, indiferent ce versiune de
  FFmpeg are utilizatorul final instalată (sau dacă nu are Homebrew
  deloc). **CONFIRMAT de Cristi (2026-09-05)**: `.pkg` de test
  (`GDCResolveEncoder-1.4.2.pkg`, nesemnat — cert Developer ID Installer
  lipsă din Keychain, instalat manual cu `sudo installer -pkg ... -target
  /`) — codecul GDC apare corect în lista din Resolve. Bug-ul de SONAME
  mismatch confirmat rezolvat definitiv, nu doar teoretic.
- Versiune 1.4.1 → 1.4.2 (PATCH — fix structural de încărcare, nicio
  schimbare de funcționalitate de encodare vizibilă). Tag-ul `v1.4.2` nu a
  fost creat/împins încă — rămâne un pas separat, de făcut când Cristi
  confirmă că vrea să publice.
