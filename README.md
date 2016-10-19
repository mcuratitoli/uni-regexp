re-nfa
===

Exam project: Linguaggi di Programmazione (2011/12) - University of Milan Bicocca

Regular expressions in Prolog

### Prolog: espressioni regolari
Le espressioni regolari (*regular expressions*, o, abbreviando *regexps*) sono tra gli strumenti più utilizzati in Informatica. Un’espressione regolare rappresenta un linguaggio (regolare), ovvero rappresenta in maniera finita un insieme potenzialmente infinito di “stringhe”.Rappresentare le espressioni regolari più semplici in Prolog è molto facile:
-  `<re1> <re2> ... <rek>` diventa `seq(<re1>, <re2>, ... , <rek>)`- `<re1> | <re2>` diventa `or(<re1>, <re2>)`- `<re>*`  diventa `star(<re>)`- `¬ <re>`  diventa `bar(<re>)`- `oneof(<re1>,<re2>,...<rek>)` (una delle `<rei`>)- `plus(<re>)` (almeno una ripetizione di  `<re>`)

### Richiesta
Lo scopo di questo progetto è di realizzare un compilatore da regexps ad NFA con altre operazioni. 

Il predicato principale da implementare è `nfa_re_compile/2`. Il secondo predicato da realizzare è `nfa_recognize/2`. Infine va realizzato il predicato `is_regular_expression/1`.
1. `is_regular_expression(RE)` è vero quando RE è un’espressione regolare. Numeri e atomi (in genere anche ciò che soddisfa `atomic/1)`, sono le espressioni regolari più semplici.2. `nfa_re_compile(FA_Id, RE)` è vero quando, dato un identificatore FA_Id per l’automa (ovvero un termine Prolog senza variabili), RE è compilabile in un automa nella base dati del Prolog.3. `nfa_recognize(FA_Id, Input)` è vero quando l’input per l’automa identificato da FA_Id viene consumato completamente e l’automa si trova in uno stato finale. Input è una lista di “simboli” dell’alfabeto riconosciuto dall’automa.
Notare che non è necessario specificare l’alfabeto Σ. Per la negazione basta semplicemente assumere che l’automa non riconosca ciò che è specificato nell’espressione regolare.


### Il codice

- `is_regular_espression(RE)`:
**caso base**: controlla che l'espressione sia atomica, 
se non lo è usa `isregex(RE)`. 
Esso usa `functor` per capire quale funtore è presente (con relativa arietà), e dopo chiama `is_regular_expression/1` per analizzare gli argomenti. In caso il funtore sia `seq` o `oneof` l'arietà non è fissa, quindi ho introdotto `increaseRE/3` che analizza uno a uno gli argomenti del relativo predicato.

- `nfa_re_compile(FA_Id,RE)`: 
verifica che l'espressione sia regolare con `is_regular_expression/1`; crea due stati, iniziale e finale e, dopo aver inserito in una lista la regexp, la divide in testa e coda, poi chiama `nfa_rc/5`:
**caso base**: in testa c'è un atomo seguito dalla lista vuota, quindi esso è la transizione tra QI e QF, gli stati iniziale e finale passati a `nfa_rc/5`; se in testa c'è uno dei funtori conosciuti crea nuovi stati iniziali e finali della sottoespressione e chiama nfa`rc/5 con le sottoespressioni.

- `nfa_recognize(FA_Id,RE)`: 
ho aggiunto un controllo in modo che dia un messaggio d'errore nel caso in cui si vuole analizzare un input su un automa non presente (per farlo ho utilizzato `findall` in modo da trovare tutti gli automi in memoria, e poi chiamato `nfa_rcgz_FA_Id_list/2` che ritorna true se l'automa esiste, altrimenti da il messaggio d'errore); poi recupera lo stato iniziale dell'automa e chiama `nfa_rcgz/3`;
**caso base**: la lista degli input è vuota, quindi o sono nello stato finale, o arrivo al finale con un numero n di mosse epsilon; se la lista degli input non è vuota controlla che il primo elemento sia una transizione permessa dall'automa, e richiama ricorsivamente `nfa_rcgz/5` sul resto della lista.

- `nfa_clear`: 
`nfa_clear/0` cancella tutto dalla memoria e resetta il gensym; `nfa_clear_nfa/1` cancella tutto riguardo un determinato automa.

- `nfa_list`:
`nfa_list/0` stampa la lista dei nomi degli automi presenti in memoria e se non ce ne sono da un messaggio d'errore (con l'ausilio di `nfa_list_name/0` e `nfa_list_control/1`), infine stampa tutti gli automi; `nfa_list/1` stampa tutte le transizione dell'automa selezionato.

