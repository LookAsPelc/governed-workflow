---
name: iron-box-orchestration
description: Jednoduchá orchestrace Codexu pro vymezenou práci, ověřování a eskalaci.
---

# Orchestrace Iron Boxu

Hlavní vlákno odpovídá za cíl uživatele, rozsah, rozhodnutí, integraci a komunikaci. Volí způsob práce a posuzuje, zda delegování přinese užitek v rámci celého zbývajícího úkolu, včetně nákladů na zadání a předání práce. Malé a zřejmé úkony proveď přímo, pokud by delegování stálo více úsilí. Srozumitelně informuj o postupu a problémech; uživatele zapoj, když je potřeba jeho rozhodnutí o záměru nebo rozsahu.

Zadání a zprávy mezi agenty, kód a komentáře piš anglicky. Výstupy piš jazykem jejich publika a s uživatelem komunikuj jeho jazykem. Když pomáhají, používej Superpowers a stávající kód, testy, specifikace a plány projektu; neudržuj souběžný stav úkolů ani obnovy pro Iron Box.

## Rozdělení práce

```text
Manager / orchestration proxy
├── Luna (High / Xhigh / Max) — programování dobře vyjasněných tasků a průzkum
├── Terra (Medium / High / Xhigh) — computer/browser use, vizuální práce a psaní
└── Sol (Low / Medium / High) — odborný úsudek a review
```

Luna je za token 20× levnější než Sol.

Nejdřív určuj potřebnou činnost, potom vhodný model a nakonec úroveň přemýšlení, kontext a ověření. Vol podle pravděpodobných nákladů na úspěšné dokončení včetně oprav, předání a ověření. Při spuštění pracovníka vyber model a výslovně nastav úroveň přemýšlení; roli a zadání přizpůsob úkolu.

- Luna: High pro mechanickou práci a rešerši, XHigh jako výchozí volba pro programování a Max pro obtížné algoritmy a provázané problémy.
- Terra: Medium pro běžnou práci v aplikacích a psaní, High pro rešerši a vizuální práci, XHigh pro náročné GUI a 3D.
- Sol: Low pro úzkou konzultaci, Medium pro architektonické alternativy, High pro závažná rozhodnutí, vědu a bezpečnost. Sol 5.6 může nabídnout odlišný nezávislý bezpečnostní pohled.

Jde o doporučení, nikoli pevné pořadí nebo hranice schopností. Podrobné příklady jsou v [model-routing.md](references/model-routing.md).

Úroveň přemýšlení se nastavuje při spuštění pracovníka; následné úkoly ji zachovávají. Než spustíš dalšího pracovníka jen kvůli změně této úrovně, zvaž zbývající práci a hodnotu čerstvého kontextu. `fork_turns` používej s `none` výjimečně s `all`; potřebuješ-li předat výřez posledních zpráv, vlož jej ručně do zprávy pracovníkovi. Zohledni i náklady na opětovné hledání a opravy, nejen délku zadání.

Vymezenou práci deleguj, když to v rámci celého úkolu ušetří významné úsilí. Souběžným pracovníkům přiděl oddělené soubory nebo odpovědnosti a překrývající se úpravy prováděj postupně. Související práci spojuj; nedělej samostatné delegování pro jednotlivé drobné kroky. Pro navazující úkoly používej stejného pracovníka, dokud je jeho kontext užitečný. Nového pracovníka zvol pro nesouvisející práci, nezávislé review, zastaralý kontext nebo když se současný pracovník zasekl.

Zadání a předání práce přizpůsob úkolu. Poskytni pracovníkovi dostatek informací o cíli, omezeních, odpovědnosti a podmínkách dokončení; při následných úkolech doplň jen relevantní změny.

## Koordinace a ověřování

Nech subagenty pracovat samostatně a doručovat průběžné zprávy, překážky a výsledky. Neprováděj pravidelný polling ani je nevyrušuj kvůli pouhému tichu či vypršení timeoutu čekání. Dokud pracují, věnuj se nezávislé koordinaci a integraci; pokud další postup závisí na jejich výsledku, pasivně čekej pomocí dostupného nástroje. Zasahuj pouze při skutečné překážce, relevantní změně požadavků, podezření na uváznutí nebo překročení výslovných omezení.
Ověřování přizpůsob práci. Před přijetím výsledku zkontroluj skutečný výstup a relevantní důkazy. Samostatné read-only review může být užitečné, když nezávislý úsudek může odhalit významný problém; pro běžné dokončení může stačit deterministická kontrola. Hlavní vlákno odpovídá za porozumění přijatému výsledku. Rozlišuj statickou konfiguraci od prokázané živé funkčnosti.
