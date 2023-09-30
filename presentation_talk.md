# 1

Ciao, sono Luca e ho svolto il mio tirocinio esterno presso ClayPaky, azienda italiana leader mondiale nella creazione e produzione di luci per lo spettacolo. Il mio tirocinio è durato 8 mesi, quindi ho molte cose da dire e poco tempo, purtroppo alcuni concetti li ho dovuti escludere.

# 2

L'industria dell'eventistica usa sempre di più visualizer pre la preview di palchi per concerti, in modo da poter progettare e programmare show in anticipo. Unreal Engine, un famoso motore grafico, ha già un plugin che implementa una sorta di visualizer. GDTF importer è una fork di questo plugin che mira ad aggiungerne le funzionalità mancanti, in particolare mire al supporto completo dei file GDTF, un formato che descrive nel dettaglio un faro.

# 3

Spiego velocemente che i fari, chiamati anche fixture, emettono luce che può essere modellata con forme e colori. Ogni singolo effetto di un faro, che può essere anche di movimento, non solo di modellazione della luce, è chiamato "feature".

# 4

Il controllo delle fixture virtuali sul nostro plugin avviene con una consolle luci che invia dati ad Unreal Engine. I fixture component sono in ascolto per questi dati e si occupano di definire come una feature si deve comportare sia ad ogni cambio di valore nei dati e sia ad ogni tick. Comunicano con gli oggetti di interpolazione per l'emulazione di motori virtuali, ed inviano i risultati ai Material Graph che si occupano del rendering della luce in se.

Quando sono entrato in azienda il task che mi è stato affidato era quello di aggiungere nuove features e completare quindi l'importazione dei GDTF. Purtroppo però dopo un primo approccio con la codebase è stato chiaro che ognuno di questi tre blocchi presentasse problemi e fosse necessario un refactoring prima di poter implementare nuove features.

# 5

Il processo di refactoring è partito dal rendering della luce ed è continuato a ritroso

# 6

Questo è un esempio di Material Graph, in particolare si occupa di renderizzare la proiezione della luce sulle superifici. Notiamo che è presente solamente il rendering di una ruota gobo, e non ci sia posto per inserire nuove features ne più istanze della stessa feature.

# 7

Una vera fixture è composta da, ovviamente, una lampada, a cui, una alla volta, vengono poste davanti tutte le varie features che possono innestarsi modificandone la forma ed il colore

# 8

Ogni feature è quindi una sorta di modulo che prende in input il risultato di quello precedente, lo modifica e lo restituisce al modulo successivo. Ed è esattamente quello che facciamo noi. Il valore del modulo m-iesimo è uguale a quello precedente meno l'inverso, perché la luce funziona sottrattivamente, dell'inverso del valore f della feature corrente.

Questo ha comportato la ricreazione delle feature preesistenti, però non è stato davvero un problema.

# 9

L'idea di implementazione è quindi di analizzare la lista di feature presenti in un file GDTF, utilizzando le API per l'editor di Unreal Engine e andare a generare un materiale che le contiene e le collega tra di loro. Il primo nodo di questa catena sarà collegato ad un colore statico, che viene elaborato all'interno dei fixture component, e l'output della fixture viene collegato all'ultimo nodo di questa catena.

# 10

Il risultato è il seguente. Notiamo a sinistra l'input, poi i due moduli collegati l'un l'altro ed alla fine l'output

# 11

Una volta sistemata e reso modulare il rendering della luce si passa al refactoring della sezione dei Fixture component

# 12

I fixture component sono di fatto una gerarchia di classi, in cui in fondo sono implementati i componenti in se che gestiscono le features

# 13

I problemi riscontrati qui sono più a livelli architetturali, in come sono stati progettati i singoli componenti ed il FixtureComponentBase. Le classi che implementato la gerarchia sono essenzialmente interfacce, che lasciano ai componenti finali l'onere di implementare completamente la loro gestione. Ciò porta a molto codice duplicato ed a classi che non arricchiscono ad arricchire le sottoclassi. Abbiamo anche molti metodi che non vengono virtualizzati nelle classi padri, e, in generale, non c'è una centralizzazione della gestione delle features. Questo porta i singoli componenti finali a dover reimplementare tutto, e, di conseguenza, è pesante e confusionario implementare nuove features

# 14

Il refactoring a questa gerarchia è stato fatto in modo che i componenti che implementano le features debbano specificare il minimo indispensabile, ovvero una funzione di inizializzazione, una funzione che viene chiamata ogni volta che arrivano nuovi dati e che si occuperà di elaborarli, una funzione che mandi in output i dati elaborati verso i parametri delle material graph, ed una funzione che specifica come il componente deve aggiornare lo stato interno ad ogni tick

# 15

FixtureComponentBase invece si occuperà di gestire tutto il resto, quindi analizzare i dati e farli effettivamente arrivare alle funzioni, inizializzare ed aggiornamento automaticamente oggetti, e così via

# 16

Una volta sistemata anche la gerarchia dei componenti è giunta l'ora di correggere l'algoritmo di interpolazione

# 17

Il funzionamento dell'algoritmo in se presenta vari bug abbastanza pesanti. Molto spesso i valori non convergono verso il target specificato, ma continuano ad alternarsi intorno. Capita anche di avere il valore che "vibra" invece di stare fermo, oppure che quando avviamo un movimento questo sarà davvero tanto lento. 

Il codice che era presente in precedenza era molto complicato e senza documentazione, quindi praticamente impossibile da modificare. 

# 18

La soluzione più semplice è purtroppo stata quella di reimplementare tutto, creando un algoritmo il più vicino possibile a quello usato dentro una fixture vera

# 19

Per scrivere il codice più in fretta ho provato a chiedere al reparto Ricerca e sviluppo dell'azienda se potessero darmi il vero codice di una fixture. Purtorppo, poiché il codice del mio progetto è opensource, non hanno giustamente voluto darmi ne il codice sorgente, ma solo un'overview generale dell'algoritmo

# 20

Il nostro algoritmo si occuperà solamente di moficiare la velocità di movimento. Lo spostamento in se viene calcolato in base a questa e verranno calcolati ad ogni tick, così come ad ogni tick verrà modificata anche la velocità.

La velocità accelera, raggiunge uno stato di velocità costante e poi decelera. Lo spostamento equivale all'integrale della funzione disegnata dalla velocità.

Il nostro obiettivo è capire quale sia il momento giusto per iniziare a decelerare.

# 21

Innanzitutto ci serve calcolare la stopDistance, ovvero la distanza percorsa dal momento che iniziamo a decelerare, usando la nostra velocità corrente come punto di partenza. 

Per farlo, prima calcoliamo il tempo che impieghiamo per decelerare, come il tempo che impieghiamo per accelerare moltiplicato alla nostra velocità.

Successivamente calcoliamo la stopDistance come l'area di un triangolo che come base ha il tempo che impieghiamo a decelerare e come altezza ha la nostra velocità

# 22

Poiché l'interpolazione non viene aggiornata di continuo, ma ad intervalli di tempo non costanti, il momento in cui dovremmo iniziare a decelerare si trova praticamente sempre tra un tick ed il precedente.

Per calcolarci il tempo t in cui iniziamo a decelerare, iniziamo a calcolare la distanza percorsa D, come la differenza tra TargetValue e la distanza che percorriamo iniziando a decelerare esattamente al tick corrente.

Distinguiamo quindi due casi abbiamo due casi:
- Se eravamo a velocità costante, quindi se la velocità S al tick iesimo è uguale al tick i - 1, possiamo rappresentare D come un semplice parallelogramma, e quindi t sarà uguale alla formula per ricavarsi la base a partire dall'area, ovvero D, e la velocità al tick corrente
- Se stavamo accelerando invece è un po' più complicato: La distanza D è rappresentabile come un parallelogramma con sopra una base poggiato un triangolo isoscele, la cui altezza è rapportata alla base in base al valore di accelerazione, e di cui l'altezza totale della figura è uguale alla velocità corrente. Per ottenere il tempo t dovremo quindi risolvere un equazione di secondo grado

# 23

In realtà all'algoritmo sono state aggiunte altre piccole correzioni, che per mancanza di tempo non posso mostrare. In ogni caso, qui potete visionare una fixture virtuale che usa il mio algoritmo che si muove accanto ad una fixture vera. Come notate si muovono all'unisono

# 24

Una volta sistemati i precedenti problemi, finalmente possiamo dedicarci all'implementazione di nuove funzionalità...

# 25

...partendo dal framing system, che è un modulo composto da quattro lame dette anche flag o blade che si inseriscono all'interno del fascio di luce per ritagliarla in maniera precisa, come in foto.

# 26

Ogni lama può avere due modalità di controllo:
- A + B, dove controlliamo i due estremi della lama, oppure
- A + Rot, dove controlliamo l'inserimento e la rotazione della lama.

Per una computazione più rapida dell'effetto è stato deciso di implementare la singola blade come una equazione matematica, in cui controlliamo se la y del punto che stiamo renderizzando si trova sopra o sotto tale equazione.

# 27

La seconda funzionalità che abbiamo sviluppato è l'iris, che ritaglia l'intero fascio di luce in forma circolare, rendendolo più o meno grande. Fisicamente è costruito come se fosse il diaframma di una fotocamera.

Il calcolo dell'iris è stato anch'esso implementato come formula matematica, ed usiamo la stessa idea per il calcolo del pigreco con il metodo di montecarlo, solo che confrontiamo la distanza di un punto dal centro con il valore dell'iris

# 28

Infine è stato implementato il frost, ovvero una sfocatura, sulle feature precedenti. Piuttosto di usare il gaussian blur che è esoso in termini computazionali, ci basiamo sulle equazioni precedenti.

Come prima cosa calcoliamo una distanza d come valore assoluto tra un punto e le precedenti equazioni

# 29

Definiamo poi una funzione che remappa il valore del frost, per renderlo meno pesante

# 30

Definiamo una seconda funzione per la distanza. Se la distanza è all'interno del valore del frost, all'ora interpolala fino a raggiungere 0.

A questo punto, come vedete nella figura a sinistra, abbiamo creato un effetto che sfoca verso nero, mano mano che ci avviciniamo all'equazione, per poi tornare indietro. Noi invece vogliamo che in una direzione sfochi verso nero, mentre nell'altra sfochi verso bianco

# 31

Dividiamo quindi in due il range di remapDist e se stiamo sotto l'equazione lo prendiamo invertito, andando così a creare l'effetto che desideriamo

# 32

Purtroppo però per un effetto ottico, soprattutto a basse luminosità, la lina dell'equazione sembrerà spostarsi verso il basso, come nella figura centrale. Questo è perché l'occhio distingue più facilmente tonalità diverse di nero piuttosto che di bianco.

L'effetto che vorremmo ottenere è come quello a destra, e per farlo...

# 33

...prendiamo il valore in uscita dai calcoli precedenti e lo passiamo dentro una sigmoide, che "concentra" il passaggio da bianco a nero verso il centro, e lo sposta anche un po' verso destra

# 34

A livello di codice, tutti precedenti remapping sono stati accorpati in un'unica funzione scritta in HLSL, un linguaggio creato dalla microsoft per l'implementazione di shader 3D.

# 35

Concludo questa presentazione parlando di come sia stato purtroppo difficile lavorare con Unreal Engine. Ha un grosso problema di documentazione ed un grosso problema di engeneering a livello strutturale. 

Ad esempio, mi è capitato di avere problemi durante la generazione dei materiali, ovvero che dopo un riavvio di Unreal Engine, i nodi si scollegavano tra di loro. Dopo giorni di reverse engeneering sul codice di Unreal Engine, ho scoperto che ero obbligato a chiamare una funzione non documentata dopo aver chiamato già il costruttore. Che mi andrebbe pure bene, se solo fosse stato scritto da qualche parte

# 36

Questi problemi sono stati una costante durante lo sviluppo del progetto e sommatosi al fatto che ho dovuto riscrivere buona parte del plugin, mi hanno portato purtroppo a non finire il task iniziale dell'implementare tutte le features rimanenti.

Fortunatamente però proprio con questo refactoring che ho fatto, aggiungere queste ultime features che sono avanzate sarà un compito molti semplice

# 37

Giuro che è l'ultimissima slide, scusate. Comunque, nel corso del mio tirocinio la claypaky è stata acquisita dalla Arri, l'azienda più famosa per la produzione di fari, camere e lenti per il mondo del cinema. Poiché nel mondo del cinema si sta spostando dall'uso del greenscreen all'uso di paesaggi realizzati in 3D proprio su unreal engine e proiettati live su dei ledwall nei set cinematografici, tra l'altro con la visuale che segue le telecamere vere, Arri era già in stretto contatto con la Epic Games.

Sono riusciti quindi a darci un contatto diretto con loro, con cui al momento stiamo in trattativa per il merge del nostro codice all'interno di Unreal Engine stesso

# 38 

Grazie mille, e scusate se mi sono eventualmente dilungato