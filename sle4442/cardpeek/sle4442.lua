--[[
  sle4442.lua - Lettura di una smart card SLE4442 con Cardpeek

  Legge i 256 byte di memoria principale, i bit di protezione e il
  contatore errori PSC, usando le pseudo-APDU ACS (ACR38/ACR39), inviate
  sul normale canale dati PC/SC con card.send().

  PERCHE' CARDPEEK "DI SERIE" NON LEGGE LA SLE4442:
  gli script predefiniti coprono solo carte a microprocessore (EMV, SIM,
  passaporti, Calypso...) e non inviano i comandi ACS per le memory card
  sincrone a 2 fili. Questo script invia proprio quei comandi.

  Comandi (ACR39 Series Reference Manual, par. 8.4):
    SELECT_CARD_TYPE  FF A4 00 00 01 06   (0x06 = famiglia 2-wire SLE4442)
    READ_MEMORY       FF B0 00 <addr> <len>
    READ_PROT_BITS    FF B2 00 00 04
    READ_ERR_COUNTER  FF B1 00 00 04

  INSTALLAZIONE (Windows):
    copia questo file nella cartella degli script utente di Cardpeek,
    di solito:  %APPDATA%\cardpeek\scripts\
    (se non la trovi, vedi la scheda "logs": Cardpeek stampa i percorsi).
    Poi premi "Analyzer" e scegli "SLE 4442 (memory card)", oppure carica
    direttamente questo script.

  Nota: l'API Lua di Cardpeek puo' variare leggermente tra le versioni;
  questo script e' pensato per le versioni recenti.
]]

local CARD_TYPE_SLE4442 = 0x06
local MEM_SIZE = 256

local function sw_ok(sw)
   return sw == 0x9000
end

local function apdu(hexstr)
   return bytes.new(8, hexstr)
end

if card.connect() then
   local root = card.tree_startup("SLE 4442")

   -- ATR
   local atr = card.last_atr()
   nodes.append(root, { classname = "block", label = "ATR",
                        size = #atr, val = atr })

   -- 1) SELECT_CARD_TYPE (famiglia 2-wire SLE4442)
   local sw, resp = card.send(apdu("FF A4 00 00 01 06"))
   nodes.append(root, { classname = "item", label = "SELECT_CARD_TYPE",
                        val = bytes.new(8, string.format("%04X", sw)) })
   if not sw_ok(sw) then
      ui.question("SELECT_CARD_TYPE rifiutato (SW=" ..
                  string.format("%04X", sw) .. ").\n" ..
                  "La carta non e' una SLE4432/SLE4442 o non e' inserita bene.",
                  {"OK"})
      card.disconnect()
      return
   end

   -- 2) Lettura memoria principale, a blocchi di 16 byte
   local mem = nodes.append(root, { classname = "folder",
                                    label = "Memoria principale (256 byte)" })
   local addr = 0
   while addr < MEM_SIZE do
      sw, resp = card.send(apdu(string.format("FF B0 00 %02X 10", addr)))
      if not sw_ok(sw) then
         ui.question("Lettura fallita a 0x" .. string.format("%02X", addr) ..
                     " (SW=" .. string.format("%04X", sw) .. ")", {"OK"})
         break
      end
      nodes.append(mem, { classname = "block",
                          label = string.format("0x%02X", addr),
                          size = #resp, val = resp })
      addr = addr + 16
   end

   -- 3) Bit di protezione (primi 32 byte)
   sw, resp = card.send(apdu("FF B2 00 00 04"))
   if sw_ok(sw) then
      nodes.append(root, { classname = "block",
                           label = "Bit di protezione (primi 32 byte)",
                           size = #resp, val = resp })
   end

   -- 4) Contatore errori PSC / memoria di sicurezza
   sw, resp = card.send(apdu("FF B1 00 00 04"))
   if sw_ok(sw) then
      nodes.append(root, { classname = "block",
                           label = "Contatore errori PSC + area sicurezza",
                           size = #resp, val = resp })
   end

   card.disconnect()
else
   ui.question("Nessuna carta rilevata nel lettore.", {"OK"})
end
