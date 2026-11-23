# Osobní znalostní asistentka v onboardingu

## Záměr

Jax při onboardingu pomůže uživateli vytvořit pracovní prostor a osobní asistentku, která funguje jako druhý mozek pro práci napříč projekty. Asistentka pomáhá uživateli i ostatním agentům dohledávat souvislosti a průběžně rozvíjí vlastní znalostní bázi.

## Průběh

Onboarding bude ve skillu uspořádán jako víceúrovňový checklist v tomto pořadí. Jax podle něj sleduje postup celým onboardingem, včetně jednotlivých integrací a přizpůsobení; po odbočení se vrátí k rozpracovanému bodu a pokračuje k dalším. Pokud některý bod potřebuje součinnost uživatele, pokračuje mezitím tam, kde může, a k nedokončenému se vrátí. Pro udržení postupu použije dostupný seznam úkolů klienta nebo průběžně aktualizovaný pracovní seznam.

1. Jax pozná sebe, prostředí a uživatele.
   - **1.1 Pozná sebe:** načte `skills/iron-box-onboarding/references/jax-lore.md`. Spustí přiložený `scripts/iron_box.py activate-package`, který zkopíruje připravené soubory avatara `assets/pets/jax/pet.json` a `assets/pets/jax/spritesheet.webp` do `pets/jax` v uživatelově Codex home. V Codex Desktopu nastaví výběr avatara na `custom:jax` podle `templates/codex-desktop.recommended.toml` a ověří, zda se Jax zobrazuje. Přivítá uživatele a zmíní [Petdex](https://petdex.dev/), kde si může vybrat další mazlíčky. Postup výběru avatara v aktuálním klientovi ještě potřebuje ověřit.
   - **1.2 Pozná prostředí:** zjistí klienta, systém, dostupné nástroje a pluginy; nalezené problémy vysvětlí a pomůže vyřešit.
   - **1.3 Pozná uživatele:** zjistí zkušenosti a očekávání uživatele, aby mu další kroky dokázal přizpůsobit.
2. **Vysvětlí a nastaví Iron Box.**
   - **2.1 Motivace:** seznámí se s `docs/why-iron-box.md` a na uživatelově práci vysvětlí, proč je při složitější práci důležité držet cíl, pracovat s kontextem a přiměřeně ověřovat výsledky.
   - **2.2 Princip:** přečte `skills/iron-box-orchestration/SKILL.md` a vysvětlí, jak hlavní vlákno spolupracuje s uživatelem, deleguje subagentům a přebírá jejich výsledky. Na příkladu ukáže skill, subagenta a možnosti předání kontextu; přizpůsobí výklad schopnostem klienta.
   - **2.3 Nastavení:** podle `templates/codex-desktop.recommended.toml` nastaví podporované modely, agenty a další doporučené funkce. Vysvětlí, jak klient pracuje s globálními a projektovými instrukcemi a které z nich dostávají subagenti. Vysvětlí také nastavení schvalování a jeho možnosti.
3. **Připraví doporučené integrace a přizpůsobení.**
   - **3.1 Integrace:** nainstaluje Superpowers, Context7, find-skills a Design Doc Mermaid; nabídne také Ponytail. U každé vysvětlí její účel a použití. Při instalaci vychází z dostupných možností klienta a aktuální dokumentace; Ponytail vyžaduje Node.js a schválení hooků.
   - **3.2 Přizpůsobení:** projde s uživatelem vzdálené ovládání, ovládání počítače a prohlížeče a vzhled. Vysvětlí rozdíly mezi skilly, pluginy a MCP a ukáže, kde lze nastavení měnit.
4. **Vytvoří s uživatelem pracovní prostor a znalostní bázi.**
   - **4.1 Zmapuje práci a zdroje:** zjistí projekty, týmy, repozitáře, dokumentaci a úkoly. Prohlédne uživatelem označené složky a zjistí, kde jsou služby hostované a jaký přístup je dostupný. Ke každému vybranému zdroji si ujasní, v čem je autoritativní.
   - **4.2 Dohodne uspořádání:** navrhne umístění projektů, prostoru asistentky a znalostní báze. Vychází z existujících repozitářů a poznámek. Případné přesuny existujících projektů probere předem.
   - **4.3 Vybere nástroje:** doporučí Karpathy LLM Wiki od Astro-Han. Obsidian může nad stejnými Markdown soubory sloužit jako editor a prohlížeč. Jax s uživatelem dohodne použití nástrojů a umístění báze. [Karpathy LLM Wiki](https://github.com/Astro-Han/karpathy-llm-wiki)
   - **4.4 Nainstaluje a nastaví nástroje:** v doporučené variantě nastaví Karpathy LLM Wiki jako skill v klientovi a otevře dohodnutou složku jako vault v Obsidianu. Chybějící nástroje nainstaluje. Wiki obsahuje vlastní poznatky s odkazy. Dokumentace v Confluence, Jira a repozitářích zůstává u zdroje, kde ji asistentka přímo čte. Složka `raw/` slouží pro podklady předané jako soubory.
5. **Nastaví asistentku, zapojí ji mezi agenty a ověří její fungování.**
   - **5.1 Dohodne roli:** uživatel a Jax určí jméno, odpovědnosti a rozsah práce. Do kořenového `AGENTS.md` prostoru asistentky Jax zapíše umístění báze, zdroje, pravidla pro aktualizaci a podmínky, za kterých má asistentka znalosti hledat nebo ukládat.
   - **5.2 Připojí zdroje:** podle klienta a hostování nastaví potřebné integrace, například pro Jira a Confluence. Ověří, že asistentka umí přímo vyhledat a přečíst vybraný zdroj i pracovat s vlastní wiki. Pro dohledávání používá přednostně přístup pouze pro čtení. Zápisy do sdílené wiki zpracovává asistentka postupně.
   - **5.3 Projde ingest, dotaz a kontrolu:** na skutečném rozhodnutí s uživatelem vyzkouší uložení s odkazem na zdroj, dohledání a kontrolu odkazů a duplicit. Při změně rozhodnutí aktualizuje související články a zachová historii. Při rozporu zaznamená rozdíl a podle potřeby ověří stav v autoritativním zdroji. Běžný dotaz wiki nemění.
   - **5.4 Dohodne používání v běžné práci:** Jax založí osobní část wiki asistentky a její umístění zapíše do jejího `AGENTS.md`. Asistentka tam rovnou ukládá potvrzená rozhodnutí a užitečné poznatky s odkazem na zdroj, je-li dostupný. U nejasného rozhodnutí si vyžádá upřesnění. Jax vyzkouší, že asistentka uloží poznatek i bez výslovné pobídky.
   - **5.5 Zpřístupní asistentku:** vytvoří projekt nebo pracovní prostor v klientovi a do sdílených instrukcí podporovaných klientem doplní, kde asistentku najít, kdy se na ni obrátit a kam jí předat doplnění s odkazem na zdroj.
   - **5.6 Nastaví předání:** pokud klient podporuje komunikaci mezi vlákny, založí asistentce vlastní vlákno a do těchto instrukcí přidá větu „Na chybějící informace se můžeš zeptat ve vlákně <odkaz>.“ Dosadí skutečný odkaz na vlákno asistentky a vyzkouší předání dotazu i odpovědi. Jinak s uživatelem vyzkouší předání dotazu a výsledku prostřednictvím dohodnutého pracovního prostoru.
   - **5.7 Ověří nový kontext:** v nové konverzaci položí dotaz z běžné práce, jehož odpověď závisí na uloženém rozhodnutí. Sleduje, zda agent znalost dohledá a použije se zdrojem bez výslovného pokynu otevřít wiki. Pokud potřebuje pobídku, zaznamená zvlášť funkčnost vyhledávání a to, zda se správný postup spustil sám.

## Rozhodnutí a hranice

- Marie, struktura složek ČT, Obsidian a Atlassian jsou příklady z Lukášova prostředí, nikoli povinné názvy nebo nástroje. Jax přizpůsobí řešení konkrétnímu uživateli.
- Osobnost a odpovědnosti patří do `AGENTS.md` asistentčina prostoru; globální instrukce ostatním agentům vysvětlují, jak ji využít. Samotný soubor nezajišťuje komunikaci mezi vlákny: její nastavení závisí na schopnostech klienta.
- Alternativou by byla pevná šablona složek a integrací nebo pouhé vytvoření poznámkového adresáře. Zvolený přizpůsobený průchod lépe odpovídá různým prostředím i cíli vytvořit fungující asistentku.
- Cílem je rozšířit onboardingové instrukce, nikoli vytvářet vlastní implementaci znalostní aplikace či univerzální integrační server.

- Pokud uživatel chce komplexnější správu znalostí, Jax může nabídnout Obsidian Second Brain jako alternativu pro ukládání z konverzací, obnovu kontextu a údržbu. Pokud pilot ukáže potíže s rozpoznáním nebo opětovným použitím znalostí, porovnáme tyto postupy na stejných scénářích. Pro jeden vault bude platit jedna sada pravidel pro zápis. Případné hooky a plánované úlohy ověříme v cílovém klientovi. [Obsidian Second Brain](https://github.com/eugeniughelbur/obsidian-second-brain)

## Stav

- Průchod je zapsaný jako checklist v `skills/iron-box-onboarding/SKILL.md`, včetně pravidel pro osobní poznámky asistentky.
- Živý onboarding zatím nebyl vyzkoušen. Text a specifikaci budeme upravovat podle průběžné zpětné vazby a zjištění.
