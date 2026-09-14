# Pubblicare su Amazon KDP — guida operativa

Documento di servizio: non fa parte del libro. Raccoglie i file pronti, le
impostazioni da inserire in KDP e le cose da sistemare **prima** di premere
«Pubblica».

---

## 1. I file e dove vanno

| File | Dove si carica | Note |
|---|---|---|
| `KDP-Interno-7x10-Manuale-S26-Ultra.pdf` | Paperback → *Contenuto* → Manoscritto | 7×10", 114 pagine, font incorporati, indice con numeri di pagina, segnalibri |
| `KDP-eBook-Manuale-S26-Ultra.epub` | eBook Kindle → *Contenuto* → Manoscritto | EPUB 3, indice navigabile, figure in PNG |
| *(da fare)* copertina fronte-retro PDF | Paperback → *Contenuto* → Copertina | Vedi § 4 |
| *(da fare)* copertina fronte JPG/TIFF | eBook → *Contenuto* → Copertina | 1600×2560 px, rapporto 1:1,6 |

---

## 2. Impostazioni del cartaceo

Da inserire nella scheda **Contenuto** del paperback:

```
Inchiostro e carta ......... Colore su carta bianca *
Formato (trim) ............. 7 x 10 pollici  (17,78 x 25,4 cm)
Sangue (bleed) ............. NO — nessun elemento tocca il bordo
Finitura copertina ......... Opaca
```

\* **Attenzione al costo.** Le figure e le tabelle di questo libro usano il
colore. Su KDP la stampa a colori costa parecchio di più del bianco e nero e
alza il prezzo minimo di vendita. Due alternative:

- **Bianco e nero**: le figure restano leggibili (sono già progettate con
  contrasti forti), il costo crolla. Consigliata per la prima edizione.
- **Colore standard**: più bella, prezzo di copertina più alto.

Fai un preventivo con il calcolatore di royalty di KDP prima di decidere.

### Margini: già conformi

L'interno è impaginato con **1,9 cm su tutti i lati** (0,75"). I minimi
richiesti per un libro di questa foliazione sono 0,375" al dorso e 0,25"
sugli altri lati, quindi siamo ampiamente dentro.

Il PDF rispetta anche gli altri requisiti: **niente crocini di taglio**,
**font incorporati**, **numero di pagine pari** (KDP rifiuta i file con
pagine dispari).

---

## 3. Dichiarazioni obbligatorie

### Contenuto generato con IA — va dichiarato

KDP distingue due casi:

- **AI-generated** — testo, immagini o traduzioni *prodotti* da uno strumento
  di IA, **anche se poi li hai rivisti e corretti**. Va dichiarato.
- **AI-assisted** — contenuto che hai scritto tu e per cui l'IA ti ha aiutato
  a correggere, rifinire o fare brainstorming. Non va dichiarato.

**Il testo e le figure di questo libro ricadono nel primo caso**: sono stati
prodotti con assistenza IA su tua indicazione. La dichiarazione si fa nella
scheda **Contenuto**, al momento del caricamento.

Due cose da sapere, entrambe a tuo favore:

1. La dichiarazione è **privata**: va ad Amazon, non compare sulla pagina del
   libro, e non c'è nessuna etichetta visibile ai lettori.
2. Amazon dichiara che **non influisce** su posizionamento, visibilità o
   royalty.

Non dichiararla, invece, viola i termini di KDP e può portare al blocco del
libro o dell'account. Il costo di dichiarare è zero, quello di non farlo è
alto: dichiara.

### Marchi e guida non ufficiale

Il libro parla di un prodotto Samsung e usa il nome del prodotto nel titolo.
È legittimo — serve a identificare l'oggetto di cui tratti — ma a tre
condizioni, che l'interno già rispetta:

1. **Dire chiaramente che non è ufficiale.** La dicitura «Guida non ufficiale»
   è sul frontespizio e la pagina dei diritti contiene la dichiarazione di
   non affiliazione. **Mettila anche in copertina.**
2. **Non usare il logo Samsung** né elementi grafici che facciano sembrare il
   libro una pubblicazione ufficiale.
3. **Non usare foto o render del prodotto** di cui non hai i diritti.

---

## 4. La copertina — falla per ultima

**Il motivo è tecnico:** la copertina del cartaceo è **un unico file che
avvolge il libro** — retro, dorso e fronte insieme. La larghezza del dorso
dipende dal numero di pagine, dal tipo di carta e dal formato. Finché
l'interno non è definitivo, il numero di pagine può cambiare, e con lui il
dorso: rifaresti il file.

**Ordine corretto:**

```
1. Interno definitivo  →  2. Numero di pagine  →  3. Dorso  →  4. Copertina
```

Il disegno del **fronte** puoi portarlo avanti in parallelo quando vuoi:
è solo l'assemblaggio del file avvolgente che deve venire dopo.

### Come ricavare le misure

Nella pagina *Cover Templates* di KDP inserisci formato, tipo di carta e
numero di pagine: ti restituisce un PNG/PDF con le linee guida esatte
(dorso, tagli, sicurezza) su cui impaginare.

Con i dati attuali — 7×10", 114 pagine — il dorso è nell'ordine dei **6 mm**
su carta bianca, ma **non usare questo numero**: generalo dal template quando
l'interno è chiuso.

### Per l'eBook

Serve **solo il fronte**, come immagine: 1600×2560 px, rapporto 1:1,6, JPG o
TIFF. Nessun dorso, nessun retro. Questa puoi farla subito.

### Cosa mettere nel retro (cartaceo)

- due o tre righe che dicono a chi serve il libro;
- tre o quattro punti elenco con i contenuti concreti;
- la dicitura **«Guida non ufficiale — non affiliata a Samsung»**;
- lo spazio bianco in basso a destra per il codice a barre (lo aggiunge KDP).

---

## 5. Metadati

**Titolo e sottotitolo.** Il sottotitolo è il posto giusto per le parole che
la gente cerca *e* per la precisazione che non è ufficiale. Per esempio:

```
Titolo:      Manuale fotocamera Samsung Galaxy S26 Ultra
Sottotitolo: Guida non ufficiale a foto e video: impostazioni, modalità Pro,
             video in Log e 20 ricette pronte all'uso
```

**Parole chiave** (sette caselle, frasi intere, non parole sciolte):

```
fotografia con smartphone · guida galaxy s26 ultra · video con il telefono
impostazioni fotocamera · modalità pro fotografia · fotografia notturna
video log color grading
```

**Categorie:** fotografia → tecnica e manuali; informatica → dispositivi
mobili. Puoi chiedere a KDP categorie aggiuntive dopo la pubblicazione.

**Descrizione:** usa l'apertura del libro come base — «Il manuale che Samsung
non mette in scatola» funziona bene come prima riga. Aggiungi l'elenco delle
cinque parti e chiudi con la precisazione che è una guida indipendente.

---

## 6. Controlli prima di pubblicare

```
□ Sostituito [IL TUO NOME] nel frontespizio e nella pagina dei diritti
□ Inserito l'ISBN (gratuito di KDP, oppure il tuo)
□ Verificata l'anteprima KDP pagina per pagina (figure e tabelle intere)
□ Deciso bianco e nero o colore, con il preventivo di royalty alla mano
□ Dichiarato il contenuto prodotto con IA
□ «Guida non ufficiale» ben visibile in copertina
□ Nessun logo Samsung, nessun render del prodotto non tuo
□ Copertina generata sul template KDP con il numero di pagine definitivo
□ Riletto il capitolo 18: le specifiche invecchiano, l'edizione va datata
```

---

## 7. Rigenerare i file

I file pubblicabili si ricostruiscono dai sorgenti Markdown di questa
cartella. Se cambi un capitolo, rigenera: l'indice e i numeri di pagina si
aggiornano da soli.

> **Nota sull'edizione.** Le specifiche di un telefono invecchiano e le voci
> di menu cambiano con gli aggiornamenti. Datare l'edizione in copertina
> («Edizione 2026») e aggiornarla quando serve è una scelta che protegge le
> recensioni.
