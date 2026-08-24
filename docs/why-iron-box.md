# Iron Box — motivace a design rationale

## Úvod: proč Iron Box vzniká

[Iron Box](https://github.com/LookAsPelc/governed-workflow) nevzniká proto, že by dnešní coding agenti byli příliš slabí.

Vzniká téměř z opačného důvodu: modely jsou už dost schopné na to, abychom jim mohli svěřit dlouhou a složitou práci. Jenže jejich schopnost **vyřešit jednotlivý problém roste rychleji než schopnost spolehlivě řídit celý dlouhý proces**.

To jsou dvě různé vlastnosti:

> **Model capability:** Dokáže model tento problém vyřešit?

versus

> **Workflow reliability:** Dokáže celý systém udržet správný cíl, stav, kontext, kontrolu a důkazy po desítky kroků?

Cílem Iron Boxu je řešit oba tyto problémy za uživatele, pokud je řešit nechce, ale zároveň mu nechat dostatek svobody aby dotohoto procesu mohl sám svým rozhodnutím vstoupit.

Je to doporučení pro organizaci práce. Je to způsob jsk hlídst věci, které model při dlouhé práci často ztratí:

* co je skutečným cílem,
* kdo právě řeší kterou část,
* jaký kontext k tomu dostal,
* co je pouze tvrzení agenta,
* co už bylo skutečně ověřeno,
* a jak pokračovat, pokud se původní kontext ztratí nebo příliš zaplní.

Jinými slovy:

> **Iron Box se nesnaží udělat model chytřejší. Snaží se vytvořit podmínky, ve kterých může svou inteligenci používat spolehlivěji.**

---

# 1. Schopnější model neřeší celý problém

[METR ve své studii dlouhých úloh](https://arxiv.org/html/2503.14499v4) ukazuje docela zřejmý vztah: čím delší úkol je, tím menší je pravděpodobnost, že ho agent dokončí správně.

Současně se situace rychle zlepšuje. **Task horizon** modelů — tedy přibližná délka úlohy, kterou ještě dokážou rozumně spolehlivě dokončit — rychle roste.

To vytváří nový problém.

Dokud agent řešil úlohu na pár minut, většina chyb byla přímo v samotném řešení.

U krátké úlohy může model:

1. přečíst zadání,
2. promyslet řešení,
3. implementovat ho,
4. otestovat ho.

U dlouhé úlohy však vzniká řetězec:

```text
zadání
  ↓
interpretace
  ↓
plán
  ↓
výzkum
  ↓
implementace A
  ↓
zpětná vazba
  ↓
změna plánu
  ↓
implementace B
  ↓
další informace
  ↓
review
  ↓
oprava
  ↓
integrace
  ↓
...
```

Každý krok může být sám o sobě rozumný.

Problém je, že každý krok zároveň přidává další možnost, že se chybný předpoklad přenese dál.

Agent například něco špatně pochopí na začátku. Později už tuto interpretaci nepovažuje za hypotézu, ale za fakt. Další kroky pak mohou být perfektně provedené — jen řeší trochu jiný problém.

Proto dlouhé úlohy nejsou jen otázkou inteligence modelu.

Jsou také otázkou **řízení práce v čase**.

---

# 2. Dlouhý kontext není spolehlivá paměť

Přirozená myšlenka zní:

> Máme obrovské context window, takže prostě necháme agenta pokračovat ve stejném vlákně.

Výzkum ale ukazuje, že to není tak jednoduché.

[Chroma ve studii Context Rot](https://www.trychroma.com/research/context-rot) testovala velké množství modelů a pozorovala, že se jejich výkon s rostoucí délkou kontextu často zhoršuje.

Nejde jen o to, zda se informace „vejde“ do context window.

Záleží také na tom:

* kolik jiných informací kolem ní je,
* jak jsou si podobné,
* kolik je v kontextu starých nebo chybných hypotéz,
* a jak je celý kontext uspořádaný.

Model tedy může mít správnou informaci fyzicky ve svém context window, ale přesto ji nemusí při rozhodování správně použít.

To vede ke dvěma důležitým závěrům:

> Informace přítomná v context window není totéž jako informace spolehlivě dostupná modelu.

A:

> Více kontextu nemusí být vždy lepší.

Staré hypotézy, opuštěné směry, review komentáře, výstupy subagentů a předchozí neúspěšné pokusy mohou začít fungovat jako šum.

Přesně to jsme pozorovali i při praktickém používání agentů.

Hlavní vlákno začne jako čisté zadání.

Po nějaké době ale obsahuje:

```text
zadání
+ plán
+ výstupy workerů
+ kus implementace
+ opravy
+ review
+ vysvětlování review
+ nový plán
+ starý plán
+ další pokusy
+ diskusi o samotném workflow
```

A právě z tohoto stále většího balíku má model rozhodnout, co je teď důležité.

Proto vzniká jedna ze základních myšlenek Iron Boxu:

> **Context is a resource, not an archive.**

Kontext je pracovní prostor.

Není to archiv, do kterého musíme navždy ukládat všechno, co se během práce stalo.

---

# 3. Root má řídit práci, ne dělat všechno sám

Z toho vzniká rozdělení na **root/managera** a **workery**.

Root drží hlavně:

* původní cíl uživatele,
* hranice úkolu,
* rozdělení práce,
* rozhodování o dalším kroku,
* spojování výsledků,
* komunikaci s uživatelem.

Worker řeší konkrétní ohraničený úkol.

```text
                    USER GOAL
                        │
                        ▼
                 ┌─────────────┐
                 │    ROOT     │
                 │   manager   │
                 └──────┬──────┘
                        │
                 malý task packet
                        │
              ┌─────────┴─────────┐
              ▼                   ▼
          Worker A            Worker B
        fresh context        fresh context
              │                   │
              └─────────┬─────────┘
                        ▼
                    výsledky
                        │
                        ▼
                   ověření
                        │
                        ▼
                      ROOT
```

Worker nepotřebuje celou historii projektu.

Potřebuje pouze informace nutné k vyřešení svého úkolu.

Tím se chrání nejen workerův kontext, ale také hlavní vlákno.

Root totiž nemusí dělat každou implementační práci sám a hromadit ve svém kontextu všechny detaily.

Jeho hlavním úkolem je **neztratit celek**.

---

# 4. Ohraničený task packet řeší několik problémů najednou

Předání práce workerovi není pokračování dlouhého chatu.

Je to nový, malý pracovní kontrakt.

Měl by obsahovat hlavně:

* co přesně má worker udělat,
* co už o problému víme,
* jaká omezení musí respektovat,
* podle čeho poznáme, že je práce správně hotová,
* co má vrátit managerovi.

Tím řešíme několik problémů současně.

### Scope drift

Worker má řešit zadaný problém.

Nemá si sám rozšiřovat scope a „pro jistotu“ předělávat sousední části projektu.

### Context rot

Worker nezačíná s celou historií projektu.

Dostává jen informace, které skutečně potřebuje.

### Zatížení starými pokusy

Pokud předchozí agent zvolil chybnou cestu, nový agent nemusí dostat celou historii jeho uvažování.

Může dostat pouze:

* problém,
* současná fakta,
* omezení,
* kritéria úspěchu.

### Paralelní práce

Pokud jsou dva úkoly skutečně nezávislé, každý může dostat vlastní čistý kontext.

### Obnova práce

Jednotkou práce už není neurčitý úsek dlouhého chatu.

Je jí konkrétně popsaný task.

Podobný princip používá i [LongHorizon-Harness](https://arxiv.org/html/2608.01964v1), jehož [implementace je veřejně dostupná na GitHubu](https://github.com/AMAP-ML/LongHorizon-Harness).

Ten každý krok popisuje jako jasně ohraničený podúkol s cílem, omezeními, kritérii úspěchu a relevantními důkazy z předchozí práce.

Iron Box ale tento princip používá záměrně jednodušeji.

Malý úkol nepotřebuje kolem sebe celý nový procesní aparát.

---

# 5. Fresh context není jen ztráta paměti

Nové context window se často chápe jako nepříjemnost:

> Agent zapomněl předchozí konverzaci.

Pro Iron Box je ale **fresh context také užitečný nástroj**.

Představme si, že agent vytvoří řešení a ověření ukáže, že je špatně.

Jedna možnost je říct stejnému agentovi:

> Tohle nefunguje. Oprav to.

Někdy je to správně.

Ale agent už zná vlastní řešení, vlastní hypotézy a vlastní předchozí úvahy. Má tedy přirozenou tendenci opravovat právě tuto cestu.

Druhá možnost je:

```text
stejný problém
+ aktuální ověřená fakta
+ stejná kritéria úspěchu
+ nový agent
+ čistý kontext
```

Nový agent nemusí vědět, jak přesně předchozí pokus vznikl.

Ví pouze, co má být výsledkem a co už bylo skutečně zjištěno.

To je jedna z myšlenek, kde se Iron Box potkává s přístupem známým z **GSD-style workflow**: neúspěšný pokus nemusí znamenat nekonečnou opravu stejného řešení. Někdy je levnější a spolehlivější udělat nový, čistý pokus.

[LongHorizon-Harness](https://arxiv.org/html/2608.01964v1) používá podobnou myšlenku systematicky. Detailní pracovní kontext executora po kroku nepřenáší dál. Další executor dostane nový kontext a kompaktní stav úlohy.

Také [Anthropic při experimentech s long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) zjistil, že samotné zkracování starého kontextu nestačí. Velkou hodnotu měly malé kroky a explicitní soubory se stavem práce, ze kterých mohl nový agent rychle zjistit, kde pokračovat.

---

# 6. Worker report není důkaz

Toto je jedna z nejdůležitějších zásad Iron Boxu:

> **Agent output is a claim, not proof.**

Worker může napsat:

* „tests pass“,
* „bug je opraven“,
* „API tuto funkci podporuje“,
* „implementace splňuje zadání“.

Ale samotné tvrzení workera ještě neznamená, že je to pravda.

Stejný agent totiž řešení vytvořil a zároveň ho hodnotí.

To je podobné, jako kdyby programátor napsal:

> Kód jsem dokončil a můžu potvrdit, že v něm nejsou chyby.

Je to užitečná informace.

Není to ale nezávislý důkaz.

[LongHorizon-Harness](https://arxiv.org/html/2608.01964v1) právě tento problém považuje za jednu z důležitých slabin běžných agentních workflow: agent něco udělá, sám to vyhodnotí jako hotové a jeho vlastní hodnocení se potom začne používat jako fakt pro další práci.

Iron Box proto rozlišuje:

```text
WORKER REPORT
     │
     │ tvrzení
     ▼
ověření / skutečné důkazy
     │
     │ ověřený výsledek
     ▼
accepted progress
```

Stejný princip používáme normálně i v software engineeringu:

* implementace není test,
* autor není nezávislé review,
* tvrzení není důkaz.

---

# 7. Proč je užitečný fresh verifier

Nezávislý verifier není užitečný jen proto, že mu dáme jiné jméno.

Důležité je, že nezačíná uvnitř stejného kontextu jako autor řešení.

[Studie The Self-Correction Illusion](https://arxiv.org/html/2606.05976v2) ukázala zajímavý efekt.

Modely dostávaly stejné chybné tvrzení, ale jednou bylo prezentováno jako jejich vlastní předchozí odpověď a podruhé jako tvrzení z externího zdroje.

V řadě experimentů byly modely výrazně ochotnější chybu opravit, když ji nevnímaly jako vlastní předchozí výstup.

Neznamená to, že self-review nikdy nefunguje.

Ukazuje to ale důležitou věc:

> **To, odkud informace přichází a v jakém kontextu ji model vidí, může ovlivnit, jak kriticky ji posoudí.**

Proto dává smysl:

```text
executor context ≠ verifier context
```

Verifier by měl znát:

* zadání,
* kritéria úspěchu,
* výsledný stav,
* potřebné důkazy,
* případně tvrzení workera.

Nemusí ale znát celou historii toho, jak worker k řešení došel.

Iron Box zároveň nechce používat verifier za každou cenu.

Pokud máme jednoduchou změnu a jasný důkaz — například test opravdu skončil úspěšně — není vždy nutné spouštět další model.

Nezávislé review má smysl tam, kde je potřeba **úsudek**, ne pouze mechanická kontrola.

---

# 8. Durable state řeší jiný problém než orchestrace

Během vývoje Iron Boxu se ukázalo, že jsou tu ve skutečnosti dva různé problémy:

1. Jak rozumně řídit práci agentů.
2. Jak pokračovat, když práce trvá dlouho a původní konverzace už není vhodná.

To není totéž.

Malý task může používat:

* managera,
* workera,
* případný verifier,

a vůbec nepotřebovat dlouhodobý stav.

Naopak dlouhá práce může potřebovat přežít:

* naplněné context window,
* zavření aplikace,
* nové vlákno,
* několik dní práce.

Proto je `$iron-box-durable-state` samostatná část.

Používá dva jednoduché soubory:

```text
task.json
state.json
```

`task.json` odpovídá na otázku:

> **Co jsme měli udělat?**

Uchovává původní cíl, důležitá omezení a kritéria úspěchu.

`state.json` odpovídá na otázku:

> **Kam jsme se zatím dostali?**

Uchovává ověřený postup, zbývající úkoly, rozhodnutí, problémy, nejistoty a slepé cesty, které už není vhodné zkoušet znovu.

```text
              TASK
      „Co jsme měli udělat?“
                │
          téměř neměnné
                │
                ▼
            task.json


              STATE
      „Kam jsme se dostali?“
                │
          průběžně se mění
                │
                ▼
            state.json
```

Toto rozdělení je důležité.

Pokud bychom původní zadání a současný stav stále přepisovali v jednom dokumentu, mohlo by se stát, že se původní cíl během práce nenápadně změní.

Jednoduše řečeno:

> `task.json` chrání původní zadání.
> `state.json` sleduje postup.

---

# 9. Ukládat fakta, ne celou historii

Durable state nemá být druhý chat log.

Jinak bychom pouze přesunuli problém dlouhého kontextu z chatu do obrovského souboru.

Cílem je něco jiného:

```text
dlouhá pracovní historie
          ↓
       výsledek
          ↓
       ověření
          ↓
   důležitý ověřený fakt
          ↓
       state.json
```

Ne:

```text
dlouhá pracovní historie
          ↓
   zkopírovat úplně vše
          ↓
  obrovský markdown soubor
          ↓
    stejný problém znovu
```

[Anthropic při práci s dlouhodobými coding agenty](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) zjistil, že explicitní progress file spolu s Git historií pomáhá novému agentovi rychle zjistit, co už bylo uděláno a kde má pokračovat.

[LongHorizon-Harness](https://arxiv.org/html/2608.01964v1) používá ještě striktnější variantu: mezi jednotlivými kroky přenáší kompaktní stav úlohy a ověřené důkazy, nikoli kompletní historii každého executora.

Iron Box používá stejnou základní myšlenku, ale v menší a praktičtější podobě.

---

# 10. Proč Terra, Luna a Sol nejsou role

Při návrhu multi-agent workflow je velmi lákavé vytvořit celý katalog agentů:

* researcher,
* debugger,
* implementer,
* tester,
* reviewer,
* architect,
* planner,
* …

A každému napsat vlastní dlouhý prompt.

Jenže tím snadno vznikne agentní cosplay místo užitečné architektury.

Stejná pravidla se začnou kopírovat mezi různými rolemi.

Každý prompt postupně roste.

Po čase není jasné:

* které pravidlo je důležité,
* které je pouze obecná výplň,
* která kopie instrukce je správná,
* kde má být změna provedena.

Přesně k tomuto problému jsme se během návrhu Iron Boxu několikrát dostali při diskusi o `roles/*.md`, TOML profilech a jednom skutečném zdroji pravdy.

Proto dnes Iron Box rozlišuje dvě věci.

### Role říká, co má agent dělat

Například:

```text
„Najdi příčinu tohoto race condition.“
```

Agent je v tomto tasku debugger.

### Execution profile říká, jak se task spustí

Například:

```text
Luna
reasoning = high
čistý kontext
potřebné nástroje
```

To je způsob provedení.

Role tedy nemusí být permanentní agent s velkým osobnostním promptem.

Může být jednoduše součástí konkrétního zadání.

Díky tomu nemusí být stejná governance pravidla rozkopírovaná do deseti různých agentů.

---

# 11. Model routing řeší hlavně cenu a potřebnou sílu modelu

Terra, Luna a Sol proto nepředstavují organizační hierarchii.

Neznamenají například:

> Luna je programátor a Sol je architekt.

Jde spíš o otázku:

> **Jak silný model pro tento krok skutečně potřebujeme?**

Doporučená logika Iron Boxu je přibližně:

```text
Terra
  ↓
root / orchestrace

Luna
  ↓
běžná práce
+ běžné nezávislé kontroly

Sol
  ↓
obtížné problémy
architektura
eskalace
high-value review
```

Smyslem je použít **nejlevnější model a nejnižší reasoning effort, který ještě dokáže úkol spolehlivě zvládnout**.

To je důležité, protože multi-agent systém má přirozenou tendenci vyrábět další práci.

Pokud každý problém automaticky dostane:

```text
3 workery
+ 2 reviewery
+ Sol arbitra
```

nevznikl spolehlivý systém.

Vznikla drahá agentní byrokracie. 🙂

Proto Iron Box používá jednoduché pravidlo:

> **Jeden worker, pokud jeden worker stačí.**

Paralelní práce má smysl hlavně tehdy, když jsou úkoly skutečně nezávislé nebo když druhý pohled přináší dostatečnou hodnotu.

---

# 12. Manager nemusí být absolutně „čistý“

[LongHorizon-Harness](https://arxiv.org/html/2608.01964v1) používá velmi striktní oddělení rolí.

Manager pouze řídí stav úlohy.

Executor pracuje v prostředí.

Auditor kontroluje výsledek.

Iron Box tento princip nepřebírá jako absolutní pravidlo.

Důvod je praktický.

Root má zůstat zaměřený hlavně na řízení, aby si nezahltil vlastní kontext a neztratil přehled.

Ale pokud je potřeba:

* přečíst jeden soubor,
* změnit drobnou věc,
* spustit jednoduchý příkaz,

nemusí mít smysl kvůli tomu vytvářet dalšího agenta.

Koordinace sama něco stojí.

Proto zde platí spíš:

> **Root má delegovat tehdy, když delegace skutečně pomáhá.**

Ne:

> Root se za žádných okolností nesmí dotknout skutečné práce.

To je jeden z důvodů, proč může Iron Box zůstat malou vrstvou nad Codexem místo nového kompletního runtime.

---

# 13. Proč verifier vrací PASS / REVISE / BLOCKED

Verifier nemá řídit celý projekt.

Má odpovědět na poměrně úzkou otázku:

> Splňuje výsledek podle dostupných důkazů to, co splňovat měl?

Iron Box proto používá tři jednoduché výsledky:

* `PASS`
* `REVISE`
* `BLOCKED`

spolu s konkrétními zjištěními, důkazy a případnou nejistotou.

```text
Verifier:
„Co podle důkazů platí?“

Manager:
„Co s tím teď uděláme?“
```

To je důležité rozdělení odpovědnosti.

Verifier například může říct:

```text
REVISE

Test X selhává kvůli změně v parseru.
```

Manager následně rozhodne:

* zda úkol vrátí původnímu workerovi,
* zda vytvoří nový fresh pokus,
* zda problém eskaluje,
* nebo zda je potřeba změnit plán.

Samotné slovo `PASS` se navíc nemá ukládat jako dlouhodobý fakt.

Lepší fakt je například:

> Integration tests X, Y a Z prošly na commitu `abc123`.

Durable state má uchovávat **to, co bylo ověřeno**, ne pouze názor reviewera.

---

# 14. Deterministický validator a LLM verifier řeší jiné otázky

Existují dva zásadně odlišné druhy kontroly.

### Deterministická kontrola

Například:

* existuje soubor?
* je JSON validní?
* má manifest správnou verzi?
* skončil test exit code `0`?
* je struktura balíčku správná?

Na takové otázky nepotřebujeme LLM.

Odpověď má být přesná a opakovatelná.

Iron Box proto obsahuje klasickou validační vrstvu, která kontroluje například strukturu package, manifesty a další pevně definovaná pravidla.

### Kontrola vyžadující úsudek

Například:

* odpovídá řešení skutečnému cíli uživatele?
* nevytvořila změna nový architektonický problém?
* jsou předložené důkazy dostatečné?
* nebyl scope úkolu nenápadně rozšířen?

Tady jednoduchý script nestačí.

Proto dává smysl LLM verifier.

```text
přesně měřitelná otázka ──► validator
otázka vyžadující úsudek ──► verifier
```

Je dobře, že tyto dvě věci zůstávají oddělené.

Používat LLM tam, kde může odpovědět obyčejný program, je nejen dražší, ale často i méně spolehlivé.

---

# 15. Portable core a Codex-specific část musí být oddělené

Iron Box začal jako workflow silně spojené s Codexem.

Postupně se ale ukázalo, že jeho hlavní principy nejsou specifické pro Codex.

Například:

* ohraničené tasky,
* worker report není důkaz,
* durable state,
* nezávislé ověření,
* práce s čistým kontextem,

jsou obecné principy agentního workflow.

Proto se projekt přesunul k obecnějšímu standardu [Agent Plugins](https://agent-plugins.org/).

Naopak věci jako:

* Codex TOML profily,
* dostupnost konkrétního modelu,
* Luna konfigurace,
* Codex marketplace,
* konkrétní způsob aktivace profilu,

jsou vlastnosti konkrétního klienta.

Architektura proto vypadá spíš takto:

```text
          IRON BOX CORE
       governance / skills
              │
        obecné principy
              │
     ┌────────┴────────┐
     ▼                 ▼
   Codex            jiný host
integration         integration
```

Toto oddělení řeší dvě věci.

První je **přenositelnost**.

Druhá je možná ještě důležitější:

> Do obecné filozofie Iron Boxu se nemají dostat workaroundy pro jednu konkrétní verzi Codexu.

To jsme během vývoje prakticky zažili například u podpory Luny nebo při přechodu na standard Agent Plugins.

Klient se může změnit.

Základní princip by kvůli tomu neměl být přepisován.

---

# 16. Proč onboarding není součást orchestrace

Iron Box může být technicky správně navržený a přesto obtížně použitelný.

Uživatel by neměl potřebovat předem vědět:

* které profily existují,
* co znamená Terra, Luna a Sol,
* která část je obecná,
* která část je Codex-specific,
* co se nastavuje automaticky,
* co musí potvrdit uživatel,
* co je skutečně ověřeno a co pouze nakonfigurováno.

Proto existuje onboarding a Jax.

Jax řeší otázku:

> **Jak Iron Box správně zprovoznit a pochopit?**

Orchestration řeší:

> **Jak podle těchto pravidel pracovat?**

Durable state řeší:

> **Jak pokračovat v práci z nového kontextu?**

Validator řeší:

> **Je samotný package a jeho konfigurace v pořádku?**

```text
Jax
= setup a vysvětlení

Orchestration
= řízení běžné práce

Durable state
= pokračování dlouhé práce

Validator
= přesná kontrola balíčku a konfigurace
```

Jsou to čtyři různé problémy.

Proto je dobré, že mají čtyři různé mechanismy.

Po dokončení onboardingu není důvod, aby Jax zasahoval do každého dalšího tasku.

---

# 17. Co nás k tomu vedlo při skutečném používání

Výzkumné práce jsou důležitým podkladem.

Iron Box ale nevznikl jen přečtením několika studií.

Velká část jeho designu vznikla z opakovaných problémů při skutečné práci s Codexem a subagenty.

## 17.1 Hlavní vlákno se snadno zanese

Pokud orchestrátor zároveň:

* komunikuje s uživatelem,
* čte všechny výstupy workerů,
* implementuje,
* analyzuje review,
* opravuje vlastní chyby,

postupně ztrácí výhodu globálního pohledu.

Proto vznikla preference:

> hlavní thread držet hlavně pro orchestraci a podrobnou práci přesouvat do samostatných kontextů.

---

## 17.2 Neviditelná orchestrace se špatně řídí

Pokud uživatel nevidí:

* který agent byl spuštěn,
* jaký model používá,
* jaký reasoning effort dostal,
* co mu bylo předáno,

špatně pozná, zda orchestrátor opravdu používá workflow tak, jak má.

Proto Iron Box požaduje před delegací ukázat například:

```text
role | model | reasoning effort | context being passed
```

Není to kosmetický log.

Je to jednoduchý **debugovací pohled na orchestraci**.

Uživatel díky němu může rychle poznat například:

> Proč jsi na tuhle triviální věc poslal Sol?

nebo:

> Proč worker dostal celé předchozí vlákno?

---

## 17.3 Orchestrátor může příliš snadno měnit plán

Při praktických testech se objevoval i jiný problém.

Uživatel dodal jednu novou informaci a orchestrátor místo malé opravy někdy přestavěl celý plán.

Místo:

```text
nová informace
→ upravit jednu část plánu
```

vzniklo:

```text
nová informace
→ znovu interpretovat celý problém
→ nový research
→ noví workeři
→ nový plán
```

Proto dává smysl jednoduchá zásada:

> **Měň pouze tu část plánu, kterou nová informace skutečně zneplatnila.**

Pokud už byla část práce správně dokončená a ověřená, není důvod ji dělat znovu.

---

## 17.4 Multi-agent workflow má tendenci samo růst

Jakmile model dostane možnost spawnovat subagenty, začne být velmi lákavé použít je všude.

Více agentů ale neznamená automaticky lepší výsledek.

Každý další agent přidává:

* tokeny,
* čas,
* další koordinaci,
* další výstup k přečtení,
* možnost konfliktu mezi výsledky.

Proto Iron Box klade důraz na jednoduché pravidlo:

> **Fan-out musí mít konkrétní důvod.**

Dva workery mají smysl, pokud řeší skutečně nezávislé části nebo pokud chceme dva nezávislé pohledy.

Ne jen proto, že můžeme spawnovat dva workery.

---

## 17.5 Dlouhé role-prompty se snadno mění v AI slop

Při návrhu specializovaných agentů jsme také viděli, jak rychle jednoduchý prompt naroste.

Začne například takto:

> Review this implementation.

A skončí jako několik odstavců:

> Be rigorous. Think deeply. Be proactive. Maintain architectural integrity. Consider edge cases. Ensure quality...

Vypadá to profesionálně.

Často to ale říká velmi málo konkrétního.

Stejná obecná pravidla se navíc začnou kopírovat mezi více agenty.

Iron Box se proto snaží držet:

> **málo trvalých pravidel a hodně konkrétního kontextu k aktuálnímu tasku.**

Ne obráceně.

---

# 18. Proč jsou části Iron Boxu oddělené

Jednotlivé části nejsou oddělené jen proto, aby projekt vypadal modulárně.

Každá hranice chrání před jiným problémem.

| Oddělení                          | Co tím řešíme                                                   |
| --------------------------------- | --------------------------------------------------------------- |
| Root × worker                     | root se nezahltí detaily a worker nedostane zbytečnou historii  |
| Worker × verifier                 | autor řešení není jediný, kdo rozhoduje o jeho správnosti       |
| `task.json` × `state.json`        | současný stav nepřepíše původní zadání                          |
| Historie × durable state          | dlouhodobá paměť se nezmění v další obrovský kontext            |
| Role × model profile              | druh práce není zbytečně svázán s konkrétním modelem            |
| Luna × Sol                        | silnější a dražší model se používá jen tam, kde přináší hodnotu |
| Validator × LLM verifier          | přesné věci kontroluje program, ne pravděpodobnostní model      |
| Portable core × Codex integration | Codex-specific workaroundy se nestanou obecnou filozofií        |
| Onboarding × orchestrace          | setup logika nezatěžuje každý další task                        |
| Orchestrace × durable state       | malé úkoly nepotřebují zbytečnou ceremonii                      |

Obecné pravidlo tedy zní:

> **Odděluj části podle toho, jaký problém řeší — ne podle toho, kolik různých agentů dokážeš pojmenovat.**

---

# 19. Iron Box není LongHorizon-Harness

[LongHorizon-Harness](https://arxiv.org/html/2608.01964v1) je pro Iron Box důležitý hlavně proto, že nezávisle potvrzuje několik stejných problémů.

Jeho architektura odděluje:

```text
Manage
Execute
Audit
```

tedy:

* správu úlohy,
* samotnou práci,
* nezávislou kontrolu.

Používá také fresh context pro jednotlivé executory a explicitní stav úlohy.

Výsledky ukazují, že taková změna harnessu může výrazně zlepšit výkon na dlouhých úlohách.

Iron Box ale není pokus [LongHorizon-Harness](https://github.com/AMAP-ML/LongHorizon-Harness) překopírovat.

LongHorizon-Harness je vlastní runtime kolem agentů.

Iron Box chce zůstat malou vrstvou nad nativní orchestrací hosta, například Codexu.

Proto:

* ne každý krok potřebuje auditora,
* root může někdy drobnou práci udělat sám,
* durable state je volitelný,
* modelové profily jsou jen pomůcka,
* samotný Codex zůstává execution enginem.

To je záměr.

Výzkum může ukázat problém a mechanismus, který pomáhá.

Není nutné kvůli tomu kopírovat celý výzkumný systém.

---

# 20. Co Iron Box záměrně není

Je užitečné říct nejen, co Iron Box je, ale také čím se stát nemá.

Iron Box nemá být:

**Agentní firma.**
Nepotřebujeme simulovat organizaci plnou managerů, researcherů, architectů a testerů.

**Systém maximalizující autonomii.**
Cílem není udělat co nejvíce kroků bez člověka. Cílem je udělat užitečnou práci spolehlivě.

**Prompt framework.**
Hodnota Iron Boxu nemá být v desítkách propracovaných persona promptů.

**Povinná ceremonie.**
Malý task má zůstat malý.

**Archiv celé konverzace.**
Durable state má uchovávat stav problému, ne přepis chatu.

**Systém, kde všechno musí posoudit Sol.**
Síla kontroly má odpovídat složitosti a riziku úkolu.

---

# 21. Nejmenší možná definice Iron Boxu

Pokud bychom celý projekt zredukovali na několik nejdůležitějších pravidel, zůstalo by asi toto:

1. **Root drží cíl a spojuje výsledky.**
2. **Worker dostává malý, jasně ohraničený task a pouze potřebný kontext.**
3. **Tvrzení workera ještě není ověřený fakt.**
4. **Tam, kde je to důležité, výsledek kontroluje skutečný důkaz nebo nezávislý verifier.**
5. **Dlouhá práce ukládá kompaktní ověřený stav mimo chat.**
6. **Fresh context je nástroj, ne pouze nepříjemná ztráta paměti.**
7. **Role říká, co se má dělat; model profile říká, čím a jak se to provede.**
8. **Použije se nejlevnější model, který úkol spolehlivě zvládne.**
9. **Více agentů se použije jen tehdy, když to má konkrétní přínos.**
10. **Základní pravidla zůstávají malá a pokud možno nezávislá na konkrétním klientovi.**

Všechno ostatní je implementace.

---

# Závěr

Iron Box vzniká z poznání, že další krok ve vývoji coding agentů není pouze:

> „Dej agentovi inteligentnější model.“

Stejně důležité je:

> **„Vytvoř prostředí, ve kterém může inteligentní model zůstat spolehlivý i při dlouhé práci.“**

[Context Rot](https://www.trychroma.com/research/context-rot) ukazuje, že dlouhé context window není bezchybná paměť a více kontextu nemusí vždy pomáhat.

[METR](https://arxiv.org/html/2503.14499v4) ukazuje, že délka úlohy stále silně souvisí s pravděpodobností selhání, přestože se schopnosti modelů rychle zlepšují.

[Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) popsal při reálných experimentech problémy s dlouhými coding sessions a význam malých kroků a explicitního stavu práce.

[The Self-Correction Illusion](https://arxiv.org/html/2606.05976v2) ukazuje, že model může být méně kritický k vlastnímu předchozímu tvrzení než ke stejnému tvrzení prezentovanému jako externí informace.

A [LongHorizon-Harness](https://arxiv.org/html/2608.01964v1) ukazuje, že oddělení správy úlohy, fresh execution, nezávislé kontroly a persistentního stavu může mít na dlouhých úlohách výrazný praktický efekt.

Naše vlastní zkušenosti s vývojem Iron Boxu ale přidávají ještě druhou část:

> **Ani správné principy nepomohou, pokud z nich vytvoříme překomplikovaný agentní aparát.**

Proto Iron Box směřuje k minimalismu.

Ne více promptů, ale jasnější hranice.

Ne více agentů, ale lepší delegace.

Ne více historie, ale lepší stav.

Ne více sebejistoty, ale lepší důkazy.

A ne nový harness, pokud několik dobře zvolených pravidel dokáže výrazně zlepšit ten existující.

V tomto smyslu není „box“ další agent.

Je to **malá řídicí konstrukce kolem agentů**, která má zabránit tomu, aby se jejich rostoucí schopnosti ztratily v dlouhém, hlučném a špatně kontrolovaném procesu.
