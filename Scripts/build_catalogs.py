#!/usr/bin/env python3
"""Writes the String Catalogs (English source, Norwegian Bokmål translations).

Usage: python3 Scripts/build_catalogs.py   (then: python3 Scripts/strings_audit.py)

Edit the tables below and re-run; the .xcstrings files are generated.
Xcode keeps them in sync afterwards, so this script is only needed for bulk edits.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# key -> Norwegian Bokmål. A tuple (one, other) for English and Norwegian makes a plural entry:
# key -> {"en": (one, other), "nb": (one, other)}
APP = {
    # Onboarding
    "Your phone,\n%@": "Telefonen din,\n%@",
    "quieter.": "roligere.",
    "Pick the apps that pull you in.": "Velg appene som drar deg inn.",
    "Tap once. They stay locked until the timer ends.": "Trykk én gang. De er låst til tiden er ute.",
    "Ending early takes a slow, deliberate hold.": "Å avslutte tidlig krever et langt, bevisst trykk.",
    "Allow Screen Time access": "Gi tilgang til Skjermtid",
    "Everything stays on your iPhone. Still never sees which apps you use.":
        "Alt blir på iPhonen din. Still ser aldri hvilke apper du bruker.",
    # Choose apps
    "What pulls you in?": "Hva drar deg inn?",
    "Lock whole categories or single apps.": "Lås hele kategorier eller enkeltapper.",
    "Choose apps": "Velg apper",
    "Change apps": "Endre apper",
    "Phone and Messages always work": "Telefon og Meldinger fungerer alltid",
    "Locked during every session": "Låst i hver økt",
    "Nothing selected yet. Choose the apps, categories or websites you want to lock.":
        "Ingenting er valgt ennå. Velg appene, kategoriene eller nettstedene du vil låse.",
    "and %lld more": "og %lld til",
    "Back": "Tilbake",
    # Home
    "Settings": "Innstillinger",
    "This week": "Denne uken",
    "Shows your weekly insights.": "Viser ukeinnsikten din.",
    "Be still": "Vær still",
    "Custom": "Egen",
    "Start session": "Start økt",
    "Tap to pick apps and categories": "Trykk for å velge apper og kategorier",
    "Choose what to block": "Velg hva som skal låses",
    "Blocking %@": "Blokkerer %@",
    "%lld app": "%lld app",
    "%lld apps": "%lld apper",
    "%lld category": "%lld kategori",
    "%lld categories": "%lld kategorier",
    "%lld website": "%lld nettsted",
    "%lld websites": "%lld nettsteder",
    "%lld min": "%lld min",
    "%lld h": "%lld t",
    "%lld h %lld min": "%lld t %lld min",
    "%lld minute": "%lld minutt",
    "%lld minutes": "%lld minutter",
    "%lld hour": "%lld time",
    "%lld hours": "%lld timer",
    "%lld day": "%lld dag",
    "%lld days": "%lld dager",
    "reclaimed": "tatt tilbake",
    "reclaimed · %lld day streak": {
        "en": ("reclaimed · %lld day streak", "reclaimed · %lld day streak"),
        "nb": ("tatt tilbake · %lld dag på rad", "tatt tilbake · %lld dager på rad"),
    },
    # Session
    "Session on": "Økt pågår",
    "until your apps return": "til appene dine er tilbake",
    "Session ends at %@": "Økten slutter kl. %@",
    "category locked": "kategori låst",
    "categories locked": "kategorier låst",
    "app locked": "app låst",
    "apps locked": "apper låst",
    "website locked": "nettsted låst",
    "websites locked": "nettsteder låst",
    "apps & categories locked": "apper og kategorier låst",
    "%@ locked": "%@ låst",
    "urge resisted": "fristelse motstått",
    "urges resisted": "fristelser motstått",
    "Hold to end early": "Hold for å avslutte tidlig",
    "Hold for 5 seconds. A pause to ask: do I really need this?":
        "Hold i 5 sekunder. En pause for å spørre: trenger jeg egentlig dette?",
    "Strict mode is on": "Streng modus er på",
    "This session can't be ended early.": "Denne økten kan ikke avsluttes tidlig.",
    # Ended early
    "Session ended": "Økten er avsluttet",
    "You stayed still for %@. That still counts.": "Du var still i %@. Det teller likevel.",
    "You took a pause. That still counts.": "Du tok en pause. Det teller likevel.",
    "OK": "OK",
    "Start a new session": "Start en ny økt",
    # Session complete
    "%@,\nreclaimed.": "%@\ntatt tilbake.",
    "Your apps are back. Use them on purpose.": "Appene dine er tilbake. Bruk dem med vilje.",
    "streak": "på rad",
    "this week": "denne uken",
    "Go again": "En gang til",
    # Notification
    "%@, reclaimed": "%@ tatt tilbake",
    "Your apps are back. %lld day streak.": {
        "en": ("Your apps are back. %lld day streak.", "Your apps are back. %lld day streak."),
        "nb": ("Appene dine er tilbake. %lld dag på rad.", "Appene dine er tilbake. %lld dager på rad."),
    },
    # Custom duration
    "Custom duration": "Egen varighet",
    "Hours": "Timer",
    "Minutes": "Minutter",
    "Sessions are at least 15 minutes.": "En økt varer minst 15 minutter.",
    "Ends at %@": "Slutter kl. %@",
    "Set %@": "Bruk %@",
    # Paywall
    "Get your time back.": "Få tiden din tilbake.",
    "Try Still Pro free for 7 days.": "Prøv Still Pro gratis i 7 dager.",
    "Schedules that lock apps automatically": "Tidsplaner som låser apper automatisk",
    "Strict mode: no ending early": "Streng modus: ingen tidlig avslutning",
    "Weekly insights": "Ukentlig innsikt",
    "Unlock everything in Still Pro.": "Lås opp alt i Still Pro.",
    "Upgrade": "Oppgrader",
    "Not subscribed": "Ikke abonnent",
    "Screen Time couldn't update your schedules. Please try again.":
        "Skjermtid kunne ikke oppdatere tidsplanene dine. Prøv igjen.",
    "Notifications are off for Still. Turn them on in Settings → Notifications → Still.":
        "Varslinger er av for Still. Slå dem på i Innstillinger → Varslinger → Still.",
    "Custom session lengths": "Egne øktlengder",
    # Settings
    "Subscription": "Abonnement",
    "Sessions": "Økter",
    "About": "Om",
    "Restore purchases": "Gjenopprett kjøp",
    "Schedules": "Tidsplaner",
    "Pro": "Pro",
    "Strict mode": "Streng modus",
    "No way to end a session early": "Ingen måte å avslutte en økt tidlig",
    "Notify when done": "Varsle når ferdig",
    "Privacy": "Personvern",
    "Terms": "Vilkår",
    "Contact": "Kontakt",
    "Rate Still": "Vurder Still",
    "Still %@ · Made in Bergen": "Still %@ · Laget i Bergen",
    "Manage": "Administrer",
    "Try free": "Prøv gratis",
    "Free trial · 1 day left": "Gratis prøveperiode · 1 dag igjen",
    "Free trial · %lld days left": "Gratis prøveperiode · %lld dager igjen",
    "Active": "Aktiv",
    "Try it free for 7 days": "Prøv gratis i 7 dager",
    "Off": "Av",
    "%lld on": "%lld på",
    "Still Pro is active.": "Still Pro er aktiv.",
    "No active subscription was found for this Apple Account.":
        "Fant ikke noe aktivt abonnement for denne Apple-kontoen.",
    "Couldn't reach the App Store. Please try again.": "Fikk ikke kontakt med App Store. Prøv igjen.",
    # No access
    "Still needs Screen Time access": "Still trenger tilgang til Skjermtid",
    "It's how Still locks apps for you. Nothing about your usage leaves this iPhone.":
        "Det er slik Still låser apper for deg. Ingenting om bruken din forlater denne iPhonen.",
    "Open Settings → Screen Time": "Åpne Innstillinger → Skjermtid",
    "Allow Still under Apps with Access": "Tillat Still under Apper med tilgang",
    "Open Settings": "Åpne Innstillinger",
    "Try again": "Prøv igjen",
    # Errors
    "Something went wrong": "Noe gikk galt",
    "Couldn't start the session. Please try again.": "Kunne ikke starte økten. Prøv igjen.",
    "Screen Time couldn't schedule the session. Please try again.":
        "Skjermtid kunne ikke planlegge økten. Prøv igjen.",
    "Too many schedules are on. Turn one off and try again.":
        "For mange tidsplaner er på. Slå av én og prøv igjen.",
    # Schedules
    "Nights": "Natt",
    "Every day": "Hver dag",
    "Weekdays": "Hverdager",
    "Weekends": "Helger",
    "Lock your apps automatically, every week.": "Lås appene dine automatisk, hver uke.",
    "No schedules yet.": "Ingen tidsplaner ennå.",
    "Schedules lock the apps you chose on Home. Choose some apps first.":
        "Tidsplaner låser appene du valgte på Hjem. Velg noen apper først.",
    "Add schedule": "Legg til tidsplan",
    "Schedules run on their own, even when Still is closed. Manual sessions and schedules never cancel each other.":
        "Tidsplaner kjører av seg selv, også når Still er lukket. Manuelle økter og tidsplaner avbryter aldri hverandre.",
    "Edit schedule": "Endre tidsplan",
    "New schedule": "Ny tidsplan",
    "Name": "Navn",
    "Name, e.g. Mornings": "Navn, f.eks. Morgener",
    "Starts": "Starter",
    "Ends": "Slutter",
    "Repeat": "Gjenta",
    "Save": "Lagre",
    "Delete schedule": "Slett tidsplan",
    "Give the schedule a name.": "Gi tidsplanen et navn.",
    "Pick at least one day.": "Velg minst én dag.",
    "Schedules are at least 15 minutes.": "En tidsplan varer minst 15 minutter.",
    # Insights
    "Last 7 days": "Siste 7 dager",
    "session": "økt",
    "sessions": "økter",
    "daily average": "snitt per dag",
    "Day": "Dag",
    # Shield preview (demo) and shield
    "Be still.": "Vær still.",
    "This app can wait. Your session ends at %@.": "Denne appen kan vente. Økten din slutter kl. %@.",
    "You chose this at %@.": "Du valgte dette kl. %@.",
}

# Strings from the DesignSystem package; resolved in the app's and the widget's bundle.
DESIGN_SYSTEM = {
    "Close": "Lukk",
    "Done": "Ferdig",
    "Session complete": "Økten er fullført",
    "Step %lld of %lld": "Steg %lld av %lld",
    "Touch and hold for %lld seconds.": "Trykk og hold i %lld sekunder.",
    "Your apps are back.": "Appene dine er tilbake.",
    "ends %@": "slutter %@",
}

SHIELD = {
    "Be still.": "Vær still.",
    "Close": "Lukk",
    "This app can wait.": "Denne appen kan vente.",
    "This app can wait. Your session ends at %@.": "Denne appen kan vente. Økten din slutter kl. %@.",
    "This app can wait. %@ ends at %@.": "Denne appen kan vente. %1$@ slutter kl. %2$@.",
    "You chose this at %@.": "Du valgte dette kl. %@.",
}


def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}


def entry(value):
    if isinstance(value, dict):
        out = {}
        for lang, (one, other) in value.items():
            out[lang] = {"variations": {"plural": {"one": unit(one), "other": unit(other)}}}
        return {"localizations": out}
    return {"localizations": {"nb": unit(value)}}


def write(path, table):
    catalog = {
        "sourceLanguage": "en",
        "strings": {key: entry(table[key]) for key in sorted(table)},
        "version": "1.0",
    }
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2, separators=(",", " : "))
        f.write("\n")
    print(f"{path}: {len(table)} strings")


if __name__ == "__main__":
    write("Still/Resources/Localizable.xcstrings", {**APP, **DESIGN_SYSTEM})
    write("StillWidgets/Localizable.xcstrings", dict(DESIGN_SYSTEM))
    write("StillShieldConfig/Localizable.xcstrings", dict(SHIELD))
