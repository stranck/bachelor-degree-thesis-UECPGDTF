# 1 - 00:23

Ciao, sono Luca e ho svolto il mio tirocinio esterno presso ClayPaky, azienda italiana leader mondiale nella creazione e produzione di luci per lo spettacolo. Il mio tirocinio è durato 6 mesi, quindi ho molte cose da dire e poco tempo, purtroppo alcuni concetti li ho dovuti escludere.

# 2 - 00:46

L'industria dell'eventistica usa sempre di più visualizer per la preview di palchi per concerti, in modo da poter progettare e programmare show in anticipo. Unreal Engine, un famoso motore grafico, ha già un plugin che implementa una sorta di visualizer. GDTF importer è una fork di questo plugin che mira ad aggiungerne le funzionalità mancanti, in particolare mira al supporto completo dei file GDTF, un formato che descrive nel dettaglio un faro.

# 3 - 01:09

Spiego velocemente che i fari, chiamati anche fixture, emettono luce che può essere modellata con forme e colori. Ogni singolo effetto di un faro, che può essere anche di movimento, è chiamato "feature".

# 4 - 01:32

Il controllo delle fixture virtuali sul nostro plugin avviene con una consolle luci che invia dati ad Unreal Engine. I fixture component sono in ascolto per questi dati e si occupano di definire come una feature si deve comportare sia ad ogni cambio di valore nei dati e sia ad ogni tick. Comunicano con gli oggetti di interpolazione per l'emulazione di motori virtuali, ed inviano i risultati ai Material Graph, che si occupano del rendering della luce in se.

Quando sono entrato in azienda il task che mi è stato affidato era quello di aggiungere nuove features e completare quindi l'importazione dei GDTF. Purtroppo però dopo un primo approccio con la codebase è stato chiaro che ognuno di questi tre blocchi presentasse problemi e fosse necessario un refactoring prima di poter implementare nuove features.

# 5 - 01:55

Refactoring che è iniziato dai material graph...

# 6 - 02:18

...che presentavano l'impossibilità di aggiungere nuove features all'interno e di avere più istanze della stessa feature attive contemporaneamente

# 7 - 02:41

Una vera fixture è composta da, ovviamente, una lampada, a cui, una alla volta, vengono poste davanti tutte le varie features che possono modificarne la forma ed il colore

# 8 - 03:04

Ogni feature è quindi una sorta di modulo che prende in input il risultato di quello precedente, lo modifica e lo restituisce al modulo successivo.

# 9 - 03:27

L'idea di implementazione è quindi di analizzare la lista di feature presenti in un file GDTF ed, utilizzando le API per l'editor di Unreal Enginem andare a generare un materiale che le contiene e le collega tra di loro, creando così una pipeline per il rendering dinamica. Il primo nodo di questa catena sarà collegato ad un colore statico che viene elaborato all'interno dei fixture component, e l'output della fixture viene collegato all'ultimo nodo di questa catena.

# 10 - 03:50

Il risultato è il seguente. Notiamo a sinistra l'input, poi i due moduli collegati l'un l'altro ed alla fine l'output

# 11 - 04:13

Una volta sistemata e reso modulare il rendering della luce si passa al refactoring dei Fixture component...

# 12 - 04:36

...che di fatto sono di fatto una gerarchia di classi, in cui in fondo sono implementati i componenti in se che gestiscono le features

# 13 - 04:59

I problemi riscontrati qui sono più ad alto livello, a livello architetturale. Le classi che implementato la gerarchia sono essenzialmente interfacce, che lasciano ai componenti finali l'onere di implementare completamente la loro gestione senza alcuna centralizzazione. Ciò porta a molto codice duplicato ed a classi che non contribuiscono ad arricchire il significato delle sottoclassi. Tutto questo porta molta confusione ad una persona che si approccia per la prima volta alla scrittura di un nuovo FixtureComponent.

# 14 - 05:22

Il refactoring a questa gerarchia è stato fatto in modo che i componenti che implementano le features debbano specificare il minimo indispensabile, ovvero un costrutore, come interpretare i dati in input, come mandare in output i dati e come aggiornare lo stato interno ad ogni tick.

# 15 - 05:45

FixtureComponentBase invece si occuperà di gestire tutto il resto.

# 16 - 06:08

Una volta sistemata anche la gerarchia dei componenti è giunta l'ora di correggere l'algoritmo di interpolazione

# 17 - 06:31

...che presenta errori proprio nei suoi calcoli, ad esempio molto spesso CurrentValue non converge verso TargetValue,.

Il codice che era presente in precedenza era molto complicato e senza documentazione ne commenti, quindi purtroppo ho dovuto riscriverlo del tutto... 

# 18 - 06:54

e ne ho approfittato per scrivere un algoritmo il più vicino possibile a quello usato dentro una fixture vera

# 19 - 07:17

Ho provato a chiedere al reparto Ricerca e sviluppo dell'azienda se potessero darmi il vero codice di una fixture. Purtorppo, poiché il codice del mio progetto è opensource ed il loro codice proprietario, non hanno giustamente voluto darmi ne il codice sorgente, ma solo un'overview generale dell'algoritmo

# 20 - 07:40

Il nostro algoritmo si occuperà solamente di moficiare la velocità di movimento. Ad ogni tick la velocità viene aggiornata e viene aggiornato anche lo spostamento dal tick precedente.

La velocità accelera, raggiunge uno stato di velocità costante e poi decelera. Lo spostamento equivale all'integrale della funzione disegnata dalla velocità.

Il nostro obiettivo è capire quale sia il momento giusto per iniziare a decelerare.

# 21 - 08:03

Innanzitutto ci serve calcolare stopDistance, ovvero distanza percorriamo iniziando a decelerare con la velocità corrente, e controlliamo se percorrendo quello spazio superiamo o meno in TargetValue ed in caso iniziamo a decelerare

# 22 - 08:26

Praticamente sempre capita che il momento in cui avremmo dovuto iniziare a decelerare si trova tra il tick corrente e quello precedente

Per calcolarci il tempo t in cui iniziamo a decelerare, iniziamo a calcolare la distanceDifferenceza \\ D, come la differenza tra TargetValue e la distanza che percorriamo iniziando a decelerare esattamente al tick corrente.

Distinguiamo quindi due casi abbiamo due casi:
- Se eravamo a velocità costante possiamo rappresentare D come un semplice parallelogramma, e quindi t sarà uguale alla formula per calcolarsi la base a partire dall'area e dalla velocità corrente Si
- Se stavamo accelerando invece la distanza D è rappresentabile sempre come un parallelogramma con però sopra un triangolo isoscele, la cui altezza è rapportata alla base in base al valore di accelerazione, e di cui l'altezza totale della figura è uguale alla velocità corrente. Per ottenere il tempo t dovremo quindi risolvere un equazione di secondo grado

# 23 - 08:49

In realtà all'algoritmo sono state aggiunte altre piccole correzioni, che per mancanza di tempo non posso mostrare. In ogni caso, qui potete visionare una fixture virtuale che usa il mio algoritmo che si muove accanto ad una fixture vera. Come notate si muovono all'unisono

# 24 - 09:12

Una volta sistemati i precedenti problemi, finalmente possiamo dedicarci all'implementazione di nuove funzionalità...

# 25 - 09:35

...partendo dal framing system, che è un modulo composto da quattro lame dette anche flag o blade che si inseriscono nel fascio di luce per ritagliarla in maniera precisa.

# 26 - 09:58

Ogni lama può avere due modalità di controllo:
- A + B, dove controlliamo i due estremi della lama, oppure...
- A + Rot, dove controlliamo l'inserimento e la rotazione della lama.

L'effetto è generato controllando se la y del punto che stiamo renderizzando si trova sopra o sotto l'equazione corrispondente alla modalità di controllo.

# 27 - 10:21

La seconda funzionalità che abbiamo sviluppato è l'iris, che ritaglia l'intero fascio di luce in forma circolare.

Il calcolo dell'iris è stato anch'esso implementato come formula matematica, ed usiamo la stessa idea per il calcolo del pigreco con il metodo di montecarlo, solo che confrontiamo la distanza di un punto dal centro con il valore dell'iris.

# 28 - 10:44

Infine è stato implementato il frost, ovvero una sfocatura, sulle feature precedenti.

Come prima cosa calcoliamo una distanza d come valore assoluto tra un punto e le precedenti equazioni

# 29 - 11:07

Definiamo poi una funzione che remappa il valore del frost, per renderlo meno pesante...

# 30 - 11:30

...ed una funzione che remappi la distanza dentro il valore del frost.

A questo punto, come vedete nella figura a sinistra, abbiamo creato un effetto che sfoca verso nero, mano mano che ci avviciniamo all'equazione, per poi tornare verso il bianco una volta superata. Noi invece vogliamo che, partendo dall'equazione in una direzione sfochiamo verso nero, mentre nell'altra verso bianco.

# 31 - 11:53

Dividiamo quindi in due il range di remapDist e se stiamo sotto l'equazione lo invertiamo, andando così a creare l'effetto che desideriamo.

# 32 - 12:16

Purtroppo però siccome l'occhio umano è più bravo a distinguere tonalità diverse di nero piuttosto che di bianco, l'equazione sembra spostarsi verso il basso, come nella figura centrale

L'effetto che vorremmo ottenere è come quello a destra, e per farlo...

# 33 - 12:39

...prendiamo il valore in uscita dai calcoli precedenti e lo passiamo dentro una sigmoide, che "concentra" al centro il passaggio da 1 a 0

# 34 - 13:02

Concludo questa presentazione parlando di come sia stato purtroppo difficile lavorare con Unreal Engine. Ha un grosso problema di documentazione ed un grosso problema di engeneering a livello strutturale. 

_Se avanza tempo parlare nel dettaglio dei problemi_

# 35 - 13:25

Nel mondo del cinema ci si sta spostando dall'uso dei greenscreen all'uso di ledwall su cui vengono proiettati scenari realizzati su unreal engine, con la visuale che segue il movimento delle camere dal vivo. Durante il mio tirocinio la ClayPaky è stata acquisita dalla Arri, azienda leader per la produzione di fari camere e lenti per il cinema, che ha interesse e sta prendendo parte lei stessa in questi progetti assieme alla Epic Games. Grazie a loro sono riuscito ad ottenere un contatto diretto con la Epic e stiamo lavorando per effettuare un merge del mio plugin con il codice sorgente di Unreal Engine.

# 36 - 13:48

Grazie mille, e scusate di nuovo se mi sono dilungato troppo. Come ho detto all'inizio il tirocinio è durato più di 6 mesi, ed è stata dura condensare tutto ciò di cui mi sono occupato in queste poche slide.