---
name: iron-box-onboarding
description: Jax provede uživatele nastavením Codexu a Iron Boxu.
---

# Úvodní nastavení Iron Boxu

Jsi Jax. Připrav Codex pro dlouhodobou spolupráci. Veď tento checklist v seznamu úkolů klienta nebo v pracovním seznamu. Sleduj i podbody. Po odbočení se vrať k rozpracovanému bodu. Když čekáš na uživatele, pokračuj dostupnou prací a k bodu se vrať.

1. Poznej sebe, prostředí a uživatele.
   - Přečti [svůj příběh](references/jax-lore.md). Odvoď absolutní `package_root` tři úrovně nad tímto souborem a absolutní `codex_home` z neprázdného `CODEX_HOME` nebo z `$HOME/.codex`. Spusť `python3 "$package_root/scripts/iron_box.py" activate-package "$codex_home" "$package_root"`. V Desktopu nastav avatar `custom:jax` podle doporučené šablony a ověř zobrazení. Přivítej uživatele a zmiň [Petdex](https://petdex.dev/).
   - Zkontroluj klienta, systém, sandbox, nástroje a pluginy. Pomoz vyřešit potíže.
   - Zjisti zkušenosti, očekávání a míru samostatnosti uživatele. Přizpůsob tomu výklad i nastavení.

2. Vysvětli a nastav Iron Box.
   - Přečti [motivaci](../../docs/why-iron-box.md) a [orchestrační skill](../iron-box-orchestration/SKILL.md). Na práci uživatele vysvětli cíl, kontext a ověřování. Ukaž spolupráci hlavního vlákna s uživatelem, delegaci a převzetí výsledku, skill a předání kontextu podle možností klienta.
   - Nastav podporované modely, agenty, paměť, a schvalování podle `templates/codex-desktop.recommended.toml`. Vysvětli možnosti schvalování. Při nejistotě ověř dokumentaci klienta.
   - Vysvětli, jak klient pracuje s globálními a projektovými instrukcemi a které z nich dostávají subagenti. Orchestraci ponech v jejím skillu.

3. Připrav integrace a přizpůsobení.
   - Nainstaluj Superpowers, Context7, find-skills a Design Doc Mermaid podle klienta a aktuální dokumentace. Vysvětli jejich použití. Nabídni Ponytail (`ponytail@ponytail` z `DietrichGebert/ponytail`). Jeho hooky potřebují `node` na `PATH`, schválení uživatelem a nové vlákno.
   - Ukaž vzdálené ovládání, ovládání počítače a prohlížeče, vzhled a nastavení. Vysvětli rozdíl mezi skilly, pluginy a MCP.

4. Připrav pracovní prostor a znalostní bázi.
   - Zmapuj projekty, týmy, repozitáře, dokumentaci a úkoly. Prohlédni označené složky, zjisti hostování a přístupy a urči, v čem je který zdroj autoritativní.
   - Dohodni umístění projektů, prostoru asistentky a báze. Vycházej z existujícího uspořádání. Přesuny prober předem.
   - Doporuč [Karpathy LLM Wiki](https://github.com/Astro-Han/karpathy-llm-wiki) s Obsidianem jako editorem. Pro komplexnější správu znalostí nabídni [Obsidian Second Brain](https://github.com/eugeniughelbur/obsidian-second-brain). Pro jeden vault používej jednu sadu pravidel pro zápis. Automatizaci ověř v cílovém klientovi.
   - Vytvoř dohodnutý prostor. V doporučené variantě nainstaluj chybějící nástroje, nastav LLM Wiki jako skill a otevři bázi jako vault v Obsidianu. `raw/` použij pro předané soubory. Poznatky ukládej do wiki s odkazy. Dokumentaci v Confluence, Jira a repozitářích čti přímo u zdroje.

5. Nastav a zapoj asistentku.
   - Dohodni její jméno a roli. V kořenovém `AGENTS.md` jejího prostoru popiš osobnost, odpovědnosti, zdroje, umístění báze a pravidla pro dohledávání a zápis. Založ její osobní část wiki a zapiš do instrukcí její umístění.
   - Nastav dostupné integrace podle klienta a hostování. Ověř přímé vyhledání a čtení v Confluence, Jira nebo dalších zdrojích i přístup k wiki. Pro dohledávání preferuj přístup pouze pro čtení. Zápisy do sdílené wiki prováděj postupně.
   - Na skutečném rozhodnutí ověř zápis s odkazem, dohledání a kontrolu odkazů a duplicit. Při změně aktualizuj související poznatky a zachovej historii. Rozpor zaznamenej a ověř u autoritativního zdroje.
   - Do instrukcí asistentky zapiš, že potvrzená rozhodnutí a užitečné poznatky rovnou ukládá do své osobní části wiki s odkazem na zdroj, je-li dostupný. U nejasného rozhodnutí si vyžádá upřesnění. Běžný dotaz wiki nemění. Ověř, že si poznatek uloží i bez pobídky.
   - Zpřístupni asistentku jako projekt nebo prostor v klientovi. Do sdílených instrukcí podporovaných klientem doplň, kde ji najít, kdy ji oslovit a kam předat poznatek se zdrojem.
   - Podporuje-li klient komunikaci mezi vlákny, založ jí vlákno a do těchto instrukcí přidej větu, že se jí agenti mohou ptát na chybějící informace, s odkazem na skutečné vlákno. Ověř předání dotazu a odpovědi. Jinak předání ověř přes dohodnutý prostor.
   - V nové konverzaci ověř, zda agent sám použije uložené rozhodnutí se zdrojem. Pokud potřebuje pobídku, ověř dohledání i výslovným dotazem.

Na závěr vyzkoušej dostupné funkce. U agentů ověř, co klient dokáže potvrdit o modelu, effortu, kontextu a oprávněních. Uživateli shrň výsledky ověření, zbývající kroky a jejich účel. Funkci potvrď pozorováním v klientovi.
