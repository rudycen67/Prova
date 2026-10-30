/*
 * esp32_sle4442_sniffer.ino
 * Sniffer PASSIVO didattico del bus 2-wire della SLE4442 per ESP32.
 *
 * Ascolta i due fili CLK e I/O, riconosce le condizioni START/STOP,
 * assembla i byte (LSB-first) e li stampa sulla seriale. Durante una
 * scrittura (es. PRESENT_CODE), tra i byte compaiono i 3 byte del PSC.
 *
 * SOLO ASCOLTO: non pilota la carta. La carta e' alimentata dal lettore
 * (ACR39U). L'ESP32 e' collegato IN PARALLELO su CLK, I/O e GND.
 *
 * ================== ATTENZIONE AI LIVELLI DI TENSIONE ==================
 * Le GPIO dell'ESP32 sono a 3.3V e NON tollerano 5V. Molti lettori
 * pilotano la SLE4442 a 5V: in quel caso DEVI inserire un partitore di
 * tensione (o un level shifter) su CLK e su I/O, altrimenti danneggi
 * l'ESP32. Partitore semplice 5V->3.3V: R1=10k in serie, R2=20k verso
 * massa, prelevi il segnale sul nodo centrale. Con lettore/carta a 3.3V
 * puoi collegare diretto. In caso di dubbio: usa il partitore.
 * =======================================================================
 *
 * Collegamenti (contatti ISO-7816 della SLE4442):
 *   C3 (CLK) --[partitore]--> GPIO_CLK
 *   C7 (I/O) --[partitore]--> GPIO_IO
 *   C5 (GND) ----------------> GND dell'ESP32  (massa comune OBBLIGATORIA)
 *   NON collegare VCC (C1) ne' RST (C2): li gestisce il lettore.
 *
 * Lettura dei risultati: monitor seriale a 115200 baud (su PC, oppure su
 * telefono con un'app USB-seriale). Opzionale: un display OLED.
 *
 * Scopo DIDATTICO, su carta e lettore PROPRI.
 */

#include <Arduino.h>
#include <driver/gpio.h>

// Scegli due GPIO liberi e sicuri all'avvio sul tuo ESP32.
static const gpio_num_t PIN_CLK = GPIO_NUM_22;   // C3 CLK
static const gpio_num_t PIN_IO  = GPIO_NUM_21;   // C7 I/O

// ---- Buffer circolare di eventi, riempito dalle ISR ----
enum EvType : uint8_t { EV_BIT0, EV_BIT1, EV_START, EV_STOP };

static const size_t BUF_SZ = 8192;
volatile EvType evBuf[BUF_SZ];
volatile size_t evHead = 0;    // scritto dalle ISR
volatile size_t evTail = 0;    // letto dal loop

static inline void IRAM_ATTR pushEvent(EvType e) {
  size_t next = (evHead + 1) % BUF_SZ;
  if (next != evTail) {         // se pieno scarta (meglio perdere che bloccare)
    evBuf[evHead] = e;
    evHead = next;
  }
}

// ISR sul fronte di SALITA del CLK: il dato su I/O e' valido -> un bit.
void IRAM_ATTR isrClk() {
  int io = gpio_get_level(PIN_IO);
  pushEvent(io ? EV_BIT1 : EV_BIT0);
}

// ISR su qualunque cambio di I/O: se CLK e' ALTO -> START o STOP.
void IRAM_ATTR isrIo() {
  if (gpio_get_level(PIN_CLK)) {        // CLK alto
    int io = gpio_get_level(PIN_IO);
    // I/O ora 0 (sceso) mentre CLK alto = START; ora 1 (salito) = STOP.
    pushEvent(io ? EV_STOP : EV_START);
  }
}

void setup() {
  Serial.begin(115200);
  delay(300);
  pinMode(PIN_CLK, INPUT);
  pinMode(PIN_IO, INPUT);
  attachInterrupt(PIN_CLK, isrClk, RISING);
  attachInterrupt(PIN_IO, isrIo, CHANGE);
  Serial.println("\n== SLE4442 sniffer (ESP32) ==");
  Serial.println("In ascolto su CLK/I/O. Genera una scrittura sul lettore.");
  Serial.println("I byte di ogni messaggio appaiono tra [START] e [STOP].");
}

// ---- Assemblaggio dei byte nel loop (fuori dalle ISR) ----
static uint8_t curByte = 0;
static uint8_t nbits = 0;
static bool inFrame = false;

void loop() {
  while (evTail != evHead) {
    EvType e = evBuf[evTail];
    evTail = (evTail + 1) % BUF_SZ;

    switch (e) {
      case EV_START:
        Serial.print("\n[START]");
        inFrame = true;
        curByte = 0; nbits = 0;
        break;

      case EV_STOP:
        Serial.print("  [STOP]");
        inFrame = false;
        curByte = 0; nbits = 0;
        break;

      case EV_BIT0:
      case EV_BIT1:
        if (inFrame) {
          uint8_t bit = (e == EV_BIT1) ? 1 : 0;
          curByte |= (bit << nbits);     // LSB-first: primo bit = bit 0
          nbits++;
          if (nbits == 8) {
            Serial.printf(" %02X", curByte);
            curByte = 0; nbits = 0;
          }
        }
        break;
    }
  }
}
