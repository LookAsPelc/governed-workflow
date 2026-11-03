# Volba modelu a ověřování

Zvol pracovníka podle potřebné činnosti, nikoli pouze podle tématu nebo velikosti zadání. Výchozí volby uprav podle dostupnosti modelů, náročnosti uvažování, zkušenosti pracovníka a výsledků. Nedostupný model či effort nepředstírej; zvol vhodnou dostupnou alternativu a omezení sděl.

| Činnost | Doporučený začátek |
| --- | --- |
| Mechanická úprava, jednoduchý test, extrakce | Luna High |
| Běžná implementace, endpoint, oprava chyby | Luna XHigh |
| Obtížný algoritmus, provázané části nebo souběh | Luna Max; při nejasné příčině Sol High |
| Architektura a kompromisy | Sol Medium; High při zásadních důsledcích |
| Formuláře a běžná práce v aplikaci | Terra Low |
| Vícekrokové GUI, vizuální kontrola, rešerše | Terra Medium; XHigh pro složitý výkres či 3D |
| Dokumentace a komunikace | Terra Medium/High; Sol pro obtížný odborný obsah |
| Publikace a bibliografie | Luna High, s ověřením primárních zdrojů |
| Extrakce dat a Python | Luna High/XHigh pro extrakci, Max pro obtížné zpracování; Terra pro složité grafy |
| XRD, DSC, TGA a experimenty | Sol High pro interpretaci a návrh experimentů |
| SEM/TEM a odborné grafy | Terra High pro obraz, Sol High pro vědecký závěr |
| Matematické odvození | Sol High, podle potřeby symbolický výpočet |
| Frontend podle předlohy | Luna XHigh/Max pro implementaci, Terra High pro vizuální kontrolu |
| CSS a responzivita | Luna XHigh, Terra High pro vizuální kontrolu |
| Blender nebo CAD | Terra High/XHigh pro GUI, Luna Max pro parametrické skriptování; Sol pro obtížnou geometrii |
| Vizuální identita nebo UX | Terra High; Sol Medium pro kritiku podle potřeby |
| Zabezpečení a threat modeling | Sol 6.1 High; Sol 5.6 jako případný nezávislý druhý názor |

U vědecké práce odděluj měření, výpočty, interpretace a hypotézy. U vizuálních výstupů ověř kromě funkčnosti také jejich vzhled. Sol může dostat otázku, aniž by přebíral implementaci nebo rozhodování o rozsahu.

Luna Max dává smysl rovnou u provázaných částí systému, rekonstrukce neznámého algoritmu nebo obtížné kauzální analýzy. Počet souborů sám náročnost neurčuje. Rozsáhlou implementaci může zpracovat Luna; Sol pak na základě výsledku může odpovědět na odborné otázky, například zda strategie/algoritmus/architektura dává smysl.

U GUI deleguj dosažení výsledku, ne jednotlivé kliky; ověř skutečně uložený výsledek. Bezpečnostní review zvaž podle rizik jako autentizace, autorizace, tajemství, cizí data a nedůvěryhodný vstup, nikoli podle počtu řádků.

Když výsledek selže, rozliš příčinu: chybějící údaje či přístup doplň; konkrétní chybu vrať pracovníkovi; chybný plán konzultuj; při chybějící schopnosti změň model nebo nástroj. Nedostatečné ověření řeš testem nebo nezávislým review. Rozdílné závěry porovnej s důkazy. Změna effortu a změna modelu jsou různé volby, nikoli povinný žebříček.

Ověřování vol podle rizika a ověřitelnosti: jednoduchý dobře měřitelný výsledek může ověřit přímý test; závažnější nebo obtížně ověřitelný problém může vyžadovat nezávislý odborný úsudek a více důkazů. Paralelizuj nezávislé úlohy a souběžnost zvyšuj, jen když přinese užitek.

Standardní ceny za stejné množství běžných vstupních a výstupních tokenů orientačně odpovídají poměru Luna 1 : Terra 10 : Sol 6.1 20 : Sol 5.6 40. Cena úkolu závisí i na počtu tokenů, effortu, opakování, review a kvalitě tvého delegování.
