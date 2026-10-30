#!/usr/bin/env python3
"""PostToolUse hook: rechnet UTC-Zeitstempel aus Connector-Antworten in Ortszeit um.

Der Gmail-Connector liefert `date` als ISO-8601 mit Z-Suffix, also UTC. Berlin liegt
im Sommer bei UTC+2, im Winter bei UTC+1. Wer die Rohzahl als Ortszeit liest, legt
Termine um ein bis zwei Stunden daneben. Genau das ist am 07.10.2026 passiert: aus
"08:11 UTC" wurde faelschlich "zwei Stunden vor dem 10-Uhr-Termin", richtig war
10:11 Ortszeit, also elf Minuten danach.

Der Hook haengt an jede betroffene Tool-Antwort eine Umrechnungstabelle. Damit steht
die Ortszeit im Kontext, ohne dass sich jemand daran erinnern muss.

Fail-open: jeder Fehler endet mit Exit 0 und stoert nichts.
"""
import json
import re
import sys
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

ZONE = ZoneInfo("Europe/Berlin")
MAXIMUM = 40

# 2026-10-07T08:26:42Z  und  2026-10-07T08:26:42.000Z
UTC_MUSTER = re.compile(r"\b(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})(?:\.\d+)?Z\b")

WOCHENTAGE = ("Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag")


def umrechnen(datum, uhrzeit):
    stempel = datetime.fromisoformat(f"{datum}T{uhrzeit}+00:00").astimezone(ZONE)
    versatz = int(stempel.utcoffset().total_seconds() // 3600)
    return stempel, versatz


def main():
    try:
        daten = json.load(sys.stdin)
    except Exception:
        return 0

    name = daten.get("tool_name") or ""
    if "Gmail" not in name and "Calendar" not in name:
        return 0

    antwort = daten.get("tool_response")
    if not isinstance(antwort, str):
        try:
            antwort = json.dumps(antwort, ensure_ascii=False)
        except Exception:
            return 0

    gefunden = []
    for datum, uhrzeit in UTC_MUSTER.findall(antwort):
        roh = f"{datum}T{uhrzeit}Z"
        if roh in [g[0] for g in gefunden]:
            continue
        try:
            lokal, versatz = umrechnen(datum, uhrzeit)
        except Exception:
            continue
        gefunden.append((roh, lokal, versatz))
        if len(gefunden) >= MAXIMUM:
            break

    if not gefunden:
        return 0

    gefunden.sort(key=lambda g: g[1])
    zeilen = [
        "ZEITZONEN-UMRECHNUNG (automatisch, nicht vom Modell erzeugt)",
        "Die Zeitstempel oben sind UTC. Verbindlich ist die Ortszeit Europe/Berlin:",
        "",
    ]
    for roh, lokal, versatz in gefunden:
        tag = WOCHENTAGE[lokal.weekday()]
        zeilen.append(
            f"  {roh}  ->  {tag}, {lokal.strftime('%d.%m.%Y %H:%M:%S')} Ortszeit (UTC+{versatz})"
        )
    zeilen += [
        "",
        "Jede Aussage ueber Uhrzeiten, Reihenfolgen und verpasste Termine NUR auf Basis",
        "der Ortszeit treffen, niemals auf Basis der UTC-Rohwerte.",
    ]
    print("\n".join(zeilen), file=sys.stderr)
    return 0


sys.exit(main())
