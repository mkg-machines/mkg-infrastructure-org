# MKG Platform Architecture

**Die Architektur-Dokumentation der MKG Platform**

Version: 1.0
Stand: Januar 2025

---

## Inhaltsverzeichnis

1. [Vision](#1-vision)
   - 1.1 [Was ist die MKG Platform?](#11-was-ist-die-mkg-platform)
   - 1.2 [Warum dieser Architektur-Ansatz?](#12-warum-dieser-architektur-ansatz)
2. [Architektur](#2-architektur)
   - 2.1 [Die Microkernel-Architektur](#21-die-microkernel-architektur)
   - 2.2 [Die 5 Kern-Prinzipien](#22-die-5-kern-prinzipien)
   - 2.3 [Begriffsdefinitionen](#23-begriffsdefinitionen)
3. [Der Kernel](#3-der-kernel)
   - 3.1 [Aufgaben des Kernels](#31-aufgaben-des-kernels)
   - 3.2 [Beständigkeit des Kernels](#32-beständigkeit-des-kernels)
   - 3.3 [Kernel-APIs](#33-kernel-apis)
4. [Extensions](#4-extensions)
   - 4.1 [Was ist eine Extension?](#41-was-ist-eine-extension)
   - 4.2 [Extension-Typen](#42-extension-typen)
   - 4.3 [Lebenszyklus einer Extension](#43-lebenszyklus-einer-extension)
   - 4.4 [Isolation innerhalb von Extensions](#44-isolation-innerhalb-von-extensions)
5. [Kommunikation (Events)](#5-kommunikation-events)
   - 5.1 [Grundprinzip](#51-grundprinzip)
   - 5.2 [Event-Struktur](#52-event-struktur)
   - 5.3 [Subscriptions](#53-subscriptions)
6. [Repository-Struktur](#6-repository-struktur)
   - 6.1 [Übersicht](#61-übersicht)
   - 6.2 [Abhängigkeitsregeln](#62-abhängigkeitsregeln)
7. [Entwickler-Guide](#7-entwickler-guide)
   - 7.1 [Neue Extension erstellen](#71-neue-extension-erstellen)
   - 7.2 [Checkliste vor Deployment](#72-checkliste-vor-deployment)
8. [Deployment](#8-deployment)
   - 8.1 [Environments](#81-environments)
   - 8.2 [Deployment-Flow](#82-deployment-flow)
   - 8.3 [Versionierung](#83-versionierung)

---

## 1. Vision

### 1.1 Was ist die MKG Platform?

Die MKG Platform ist eine generische, mandantenfähige **Master Data Management (MDM) Plattform** mit Meta-Modell-Architektur.

#### Was bedeutet Meta-Modell?

Bei klassischen Anwendungen sind Datenstrukturen im Code festgelegt:

| Klassischer Ansatz | |
|-------------------|---|
| Code definiert | "Ein Artikel hat: Titel, Preis, Beschreibung" |
| Änderung | Entwickler muss Code ändern, neu deployen |

Bei einem Meta-Modell definiert das System sich selbst:

| Meta-Modell-Ansatz | |
|-------------------|---|
| System definiert | "Was ist ein Entity-Typ? Was ist ein Attribut?" |
| Konfiguration | "Artikel ist ein Entity-Typ mit Attributen: Titel, Preis, Beschreibung" |
| Änderung | Administrator konfiguriert, kein Code nötig |

#### Vorteile des Meta-Modell-Ansatzes

| Vorteil | Beschreibung |
|---------|--------------|
| **Flexibilität** | Neue Entity-Typen und Attribute ohne Code-Änderung |
| **Mandantenfähigkeit** | Jeder Tenant kann eigene Datenstrukturen definieren |
| **Schnelle Anpassung** | Änderungen in Minuten statt Wochen |
| **Keine Deployment-Zyklen** | Strukturänderungen ohne Release |
| **Entkopplung** | Datenmodell ist unabhängig vom Code |

#### Die drei Architektur-Ebenen

| Ebene | Beschreibung | Wer arbeitet hier |
|-------|--------------|-------------------|
| **Meta-Meta-Ebene** | Definiert was ein Entity-Typ ist, was ein Attribut ist, was eine Relation ist | Plattform-Entwickler |
| **Meta-Ebene** | Definiert konkrete Entity-Typen, deren Attribute und Relationen | Administrator |
| **Daten-Ebene** | Enthält die eigentlichen Datensätze (Instanzen der Entity-Typen) | Endanwender |

#### Die drei Ebenen in der Praxis

**Meta-Meta-Ebene** (im Code festgelegt):
- Ein Entity-Typ hat einen Namen und Attribute
- Ein Attribut hat einen Namen und einen Datentyp
- Eine Relation verbindet zwei Entity-Typen

**Meta-Ebene** (durch Administrator konfiguriert):
- Entity-Typ "Produkt" mit Attributen: Bezeichnung (Text), Preis (Dezimalzahl), Kategorie (Relation)
- Entity-Typ "Kategorie" mit Attributen: Name (Text)

**Daten-Ebene** (durch Endanwender gepflegt):
- Produkt: "Holzfaserdämmplatte", 29.99€, Kategorie: "Dämmstoffe"
- Kategorie: "Dämmstoffe"

---

### 1.2 Warum dieser Architektur-Ansatz?

#### Das Problem klassischer Architekturen

| Ansatz | Problem |
|--------|---------|
| Monolith | Jede Änderung kann alles beeinflussen |
| Microservices | Zu granular, hoher Overhead bei Kommunikation |
| Schichtenarchitektur (Layered) | Vertikale Abhängigkeiten, schwer erweiterbar |
| Service-Oriented Architecture (SOA) | Komplex, oft schwergewichtige Integrationen |

#### Typische Symptome gewachsener Systeme

- Einfache Features benötigen Wochen oder Monate
- Entwickler müssen das gesamte System verstehen
- Ungewollte Seiteneffekte: Eine Änderung beeinflusst unbeabsichtigt andere Bereiche
- Neue Entwickler brauchen lange Einarbeitungszeit
- Angst vor Änderungen ("Never touch a running system")

#### Unser Ziel

| Klassische Architektur | MKG Platform |
|------------------------|--------------|
| Neues Feature = Code an vielen Stellen ändern | Neues Feature = Neuer isolierter Code |
| Entwickler muss System verstehen | Entwickler muss nur Schnittstelle verstehen |
| Änderung kann Bestehendes kaputt machen | Bestehendes bleibt unberührt |
| Einarbeitung in Wochen | Einarbeitung in Stunden |
| Abhängigkeiten wachsen mit jedem Feature | Keine neuen Abhängigkeiten |

---

## 2. Architektur

### 2.1 Die Microkernel-Architektur

Die MKG Platform basiert auf einer **Microkernel-Architektur** mit **Event-basierter Kommunikation**.

#### Was ist eine Microkernel-Architektur?

Eine Microkernel-Architektur besteht aus zwei Hauptkomponenten:

| Komponente | Beschreibung |
|------------|--------------|
| **Kernel** | Minimaler Kern, der nur grundlegende Infrastruktur bereitstellt |
| **Extensions** | Unabhängige Module, die Business-Logik implementieren |

Der Kernel ist bewusst klein gehalten. Er stellt nur das Nötigste bereit, damit Extensions funktionieren können. Die eigentliche Fachlogik liegt in den Extensions.

#### Übersicht

```
┌─────────────────────────────────────────────────────────────────────┐
│                            KERNEL                                    │
│              (Minimal, stabil, ändert sich selten)                  │
│                                                                      │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐             │
│  │Entity Storage │ │Schema Registry│ │   Event Bus   │             │
│  └───────────────┘ └───────────────┘ └───────────────┘             │
│                                                                      │
│  ┌───────────────┐ ┌───────────────┐                               │
│  │ Auth/Identity │ │  API Gateway  │                               │
│  └───────────────┘ └───────────────┘                               │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                    Events und APIs
                                 │
        ┌────────────────────────┼────────────────────────┐
        ▼                        ▼                        ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│  Extension A  │       │  Extension B  │       │  Extension C  │
│               │       │               │       │               │
│  Eigene DB    │       │  Eigene DB    │       │  Eigene DB    │
│  Eigene Logik │       │  Eigene Logik │       │  Eigene Logik │
└───────────────┘       └───────────────┘       └───────────────┘
```

#### Der Kernel

Der Kernel stellt **Infrastruktur** bereit – keine Business-Logik:

| Komponente | Verantwortung |
|------------|---------------|
| **Entity Storage** | Speichern, Lesen, Löschen von Entitäten |
| **Schema Registry** | Verwalten von Entity-Typen und Attributen |
| **Event Bus** | Verteilen von Events an Extensions |
| **Auth/Identity** | Authentifizierung, Mandanten, Berechtigungen |
| **API Gateway** | Routing, Rate Limiting |

#### Extensions

Extensions sind unabhängige Module, die fachliche Funktionen implementieren:

| Eigenschaft | Beschreibung |
|-------------|--------------|
| **Unabhängig** | Jede Extension funktioniert für sich alleine |
| **Eigene Daten** | Jede Extension hat ihre eigene Datenbank |
| **Isoliert** | Extensions kennen sich nicht gegenseitig |
| **Erweiterbar** | Neue Extensions können jederzeit hinzugefügt werden |

#### Event-basierte Kommunikation

Extensions kommunizieren nicht direkt miteinander. Stattdessen:

1. Eine Extension **publiziert** ein Event (was ist passiert?)
2. Der Kernel **verteilt** das Event an interessierte Extensions
3. Andere Extensions **reagieren** auf das Event

| Kommunikationsart | Beschreibung |
|-------------------|--------------|
| Extension → Extension | ❌ Nicht erlaubt |
| Extension → Kernel → Extension | ✅ Über Events |

---

### 2.2 Die 5 Kern-Prinzipien

Diese Prinzipien sind unverrückbar und leiten jede Architektur-Entscheidung.

#### Prinzip 1: Minimaler Kernel

> Der Kernel ist das Betriebssystem der Plattform – nicht die Anwendung.

- Der Kernel stellt Infrastruktur bereit, keine Business-Logik
- Der Kernel ändert sich selten und wird nur vom Core-Team gepflegt
- Alles was Business-Logik ist, gehört in Extensions

#### Prinzip 2: Unabhängige Extensions

> Jede Extension funktioniert für sich alleine.

- Extensions kennen sich nicht gegenseitig
- Extensions haben keine Abhängigkeiten untereinander
- Eine Extension kann deployed werden ohne andere zu beeinflussen
- Wenn Extension A ausfällt, funktioniert Extension B weiter

#### Prinzip 3: Kommunikation nur über Events

> Extensions reden nicht miteinander – sie reagieren auf Ereignisse.

- Keine direkten API-Aufrufe zwischen Extensions
- Alle Kommunikation läuft über den Event Bus im Kernel
- Extensions publizieren Events (was ist passiert?)
- Extensions subscriben auf Events (was interessiert mich?)

#### Prinzip 4: Isolation auf allen Ebenen

> Änderungen haben minimale Auswirkungen.

- Zwischen Extensions: Keine direkte Kopplung, nur Events
- Innerhalb Extensions: Eigene Handler pro Variante, eigene Tests
- Ein Bug-Fix in Feature A darf Feature B nicht beeinflussen

#### Prinzip 5: Schnelles Onboarding

> Ein Entwickler muss in Stunden produktiv sein, nicht in Wochen.

- Klare Dokumentation statt Tribal Knowledge
- Templates als Startpunkt
- Klar definierte Schnittstellen
- Kein Verständnis des Gesamtsystems nötig

---

### 2.3 Begriffsdefinitionen

#### Architektur

| Begriff | Definition |
|---------|------------|
| **Kernel** | Der minimale Kern der Plattform. Stellt Infrastruktur bereit, enthält keine Business-Logik. |
| **Extension** | Ein unabhängiges Modul, das Business-Logik implementiert. Hat eigene Datenbank, eigene APIs, eigene Tests. |
| **Handler** | Eine isolierte Komponente innerhalb einer Extension, die eine spezifische Variante verarbeitet (z.B. PSD-Handler, JPG-Handler). |

#### Kommunikation

| Begriff | Definition |
|---------|------------|
| **Event** | Eine Nachricht, die beschreibt was passiert ist (z.B. "asset.uploaded"). |
| **Event Bus** | Komponente im Kernel, die Events empfängt und an interessierte Extensions verteilt. |
| **Publish** | Das Veröffentlichen eines Events durch eine Extension. |
| **Subscribe** | Das Abonnieren von Events durch eine Extension. |
| **Subscription** | Eine aktive Anmeldung einer Extension für bestimmte Events. |

#### Datenmodell

| Begriff | Definition |
|---------|------------|
| **Entity** | Ein Datenobjekt in der Plattform (z.B. ein Artikel, ein Asset, ein Benutzer). |
| **Entity-Typ / Schema** | Die Definition einer Art von Entity mit ihren Attributen und Relationen. |
| **Attribut** | Eine Eigenschaft eines Entity-Typs (z.B. "Titel" vom Datentyp Text). |
| **Relation** | Eine Beziehung zwischen zwei Entity-Typen (z.B. Artikel → Kategorie). |

#### Mandantenfähigkeit

| Begriff | Definition |
|---------|------------|
| **Tenant** | Ein Mandant der Plattform. Jeder Tenant hat eigene Daten, eigene Benutzer, eigene Konfiguration. Tenants sind vollständig voneinander isoliert. |

---

## 3. Der Kernel

### 3.1 Aufgaben des Kernels

Der Kernel ist das Fundament der Plattform. Er stellt grundlegende Infrastruktur bereit, damit Extensions funktionieren können.

#### Was der Kernel bereitstellt

| Komponente | Aufgabe |
|------------|---------|
| **Entity Storage** | Speichern, Lesen, Aktualisieren, Löschen von Entitäten |
| **Schema Registry** | Verwalten von Entity-Typen und deren Attributen |
| **Event Bus** | Empfangen und Verteilen von Events an Extensions |
| **Auth / Identity** | Authentifizierung, Autorisierung, Benutzerverwaltung |
| **API Gateway** | Einheitlicher Einstiegspunkt für alle API-Anfragen |

#### Was der Kernel NICHT bereitstellt

Der Kernel enthält keine Business-Logik. Folgendes gehört in Extensions:

- Validierungsregeln
- Berechnete Felder
- Workflows
- Import / Export
- Benachrichtigungen
- Reporting
- Vorschau-Generierung
- Suchfunktionen (erweitert)

---

### 3.2 Beständigkeit des Kernels

Der Kernel ist beständig. Seine Schnittstellen ändern sich selten und werden sorgfältig geplant.

#### Warum Beständigkeit wichtig ist

| Grund | Erklärung |
|-------|-----------|
| **Abhängigkeit** | Alle Extensions bauen auf dem Kernel auf |
| **Risiko** | Eine Kernel-Änderung kann alle Extensions beeinflussen |
| **Vertrauen** | Entwickler müssen sich auf gleichbleibende Schnittstellen verlassen können |

#### Regeln für Kernel-Änderungen

| Regel | Beschreibung |
|-------|--------------|
| **Abwärtskompatibilität** | Bestehende APIs bleiben funktionsfähig |
| **Versionierung** | Breaking Changes nur über neue API-Versionen |
| **Ankündigung** | Änderungen werden frühzeitig kommuniziert |
| **Core-Team only** | Nur das Core-Team ändert den Kernel |

#### Gründe für Kernel-Änderungen

- Sicherheitsupdates
- Performance-Optimierungen
- Neue Infrastruktur-Funktionen (die alle Extensions benötigen)
- Bugfixes

#### Keine Gründe für Kernel-Änderungen

- Einzelne Tenant-Anforderungen
- Business-Logik (gehört in Extensions)
- Features die nur bestimmte Extensions benötigen

---

### 3.3 Kernel-APIs

Der Kernel stellt APIs bereit, über die Extensions mit der Plattform interagieren. Diese APIs sind der einzige Weg für Extensions, auf Kernel-Funktionen zuzugreifen.

#### Übersicht

| API | Zweck |
|-----|-------|
| **Entity API** | Erstellen, Lesen, Aktualisieren, Löschen von Entitäten |
| **Schema API** | Verwalten von Entity-Typen und deren Attributen |
| **Event API** | Veröffentlichen von Events und Verwalten von Subscriptions |
| **Auth API** | Authentifizierung und Token-Verwaltung |
| **Identity API** | Zugriff auf Benutzer- und Tenant-Informationen |

#### Prinzipien

| Prinzip | Beschreibung |
|---------|--------------|
| **RESTful** | Alle APIs folgen REST-Konventionen |
| **JSON** | Einheitliches Datenformat für Request und Response |
| **Tenant-Isolation** | Jeder API-Aufruf ist auf den aktuellen Tenant beschränkt |
| **Versioniert** | APIs sind versioniert (z.B. `/v1/entities`) |
| **Authentifiziert** | Jeder API-Aufruf erfordert ein gültiges Token |

#### Detaillierte API-Spezifikation

Die vollständige API-Dokumentation mit Endpunkten, Parametern und Beispielen befindet sich in der separaten **API-Referenz**.

---

## 4. Extensions

### 4.1 Was ist eine Extension?

Eine Extension ist ein unabhängiges Modul, das Business-Logik implementiert.

#### Eigenschaften

| Eigenschaft | Beschreibung |
|-------------|--------------|
| **Unabhängig** | Funktioniert ohne andere Extensions |
| **Isoliert** | Eigene Datenbank, eigener Code, eigene Tests |
| **Erweiterbar** | Kann hinzugefügt werden ohne Änderungen an bestehenden Extensions |
| **Austauschbar** | Kann entfernt oder ersetzt werden ohne Auswirkungen auf andere Extensions |

#### Möglichkeiten

Eine Extension kann:

- Auf Events reagieren
- Events veröffentlichen
- Kernel-APIs nutzen
- Eigene APIs bereitstellen
- Eigene Daten speichern

#### Einschränkungen

Eine Extension kann nicht:

- Andere Extensions direkt aufrufen
- Auf Datenbanken anderer Extensions zugreifen
- Den Kernel verändern

---

### 4.2 Extension-Typen

Es gibt zwei Typen von Extensions:

| Typ | Beschreibung |
|-----|--------------|
| **Core Extension** | Von MKG bereitgestellt, für alle Tenants verfügbar |
| **Tenant Extension** | Kundenspezifisch, nur für einen einzelnen Tenant verfügbar |

#### Core Extensions

Core Extensions werden vom MKG-Team entwickelt und gepflegt. Sie stellen grundlegende Funktionen bereit, die für alle Tenants relevant sind.

| Eigenschaft | Beschreibung |
|-------------|--------------|
| **Verfügbarkeit** | Für alle Tenants |
| **Entwicklung** | Durch MKG-Team |
| **Wartung** | Durch MKG-Team |
| **Updates** | Automatisch für alle Tenants |

#### Tenant Extensions

Tenant Extensions werden für einen spezifischen Tenant entwickelt. Sie erfüllen individuelle Anforderungen, die nur für diesen Tenant relevant sind.

| Eigenschaft | Beschreibung |
|-------------|--------------|
| **Verfügbarkeit** | Nur für einen Tenant |
| **Entwicklung** | Durch MKG-Team oder externe Entwickler |
| **Wartung** | Individuell vereinbart |
| **Updates** | Nur für diesen Tenant |

#### Isolation

| Aspekt | Core Extension | Tenant Extension |
|--------|----------------|------------------|
| Code | Gemeinsame Codebasis | Eigene Codebasis |
| Daten | Pro Tenant isoliert | Nur Daten des Tenants |
| Zugriff | Alle Tenants | Nur ein Tenant |

---

### 4.3 Lebenszyklus einer Extension

Eine Extension durchläuft folgende Phasen:

#### Übersicht

```
Entwicklung → Registrierung → Betrieb → Update
```

#### Phasen

| Phase | Beschreibung |
|-------|--------------|
| **Entwicklung** | Extension wird implementiert und getestet |
| **Registrierung** | Extension wird beim Kernel angemeldet |
| **Betrieb** | Extension empfängt Events und verarbeitet Anfragen |
| **Update** | Neue Version wird entwickelt und deployed |

#### Entwicklung

- Extension-Template klonen
- Event-Subscriptions definieren
- Handler implementieren
- Tests schreiben
- Lokal testen

#### Registrierung

- Extension beim Kernel registrieren
- Event-Subscriptions aktivieren
- APIs im Gateway registrieren (falls vorhanden)

#### Betrieb

- Extension empfängt Events vom Event Bus
- Extension verarbeitet Anfragen über eigene APIs
- Extension nutzt Kernel-APIs bei Bedarf
- Extension veröffentlicht Events

#### Update

- Neue Version entwickeln
- Testen
- Deployen (ohne andere Extensions zu beeinflussen)

---

### 4.4 Isolation innerhalb von Extensions

Auch innerhalb einer Extension muss Isolation gewährleistet sein. Eine Änderung an einer Funktion darf andere Funktionen nicht beeinflussen.

#### Das Problem

Wenn alle Varianten in einer Funktion liegen:

- Bug-Fix für Variante A kann Variante B beeinflussen
- Neue Variante C kann bestehende Varianten beeinflussen
- Tests werden unübersichtlich

#### Die Lösung: Handler

Jede Variante wird in einem eigenen Handler isoliert:

```
Extension: Vorschau-Generator
│
├── Core (Router)
│   └── Empfängt Event, routet an richtigen Handler
│
├── Handler: PSD
│   └── Eigene Logik, eigene Tests
│
├── Handler: JPG
│   └── Eigene Logik, eigene Tests
│
├── Handler: SVG
│   └── Eigene Logik, eigene Tests
│
└── Handler: PNG
    └── Eigene Logik, eigene Tests
```

#### Vorteile

| Vorteil | Beschreibung |
|---------|--------------|
| **Isolation** | Jeder Handler ist unabhängig |
| **Testbarkeit** | Jeder Handler hat eigene Tests |
| **Erweiterbarkeit** | Neue Handler ohne Änderung bestehender Handler |
| **Wartbarkeit** | Bug-Fix in einem Handler beeinflusst andere nicht |

#### Beispiel: Neues Format hinzufügen

```
Änderungen:
├── Neuer Handler: PNG
└── Neue Tests: PNG

Nicht geändert:
├── Handler: PSD
├── Handler: JPG
└── Handler: SVG
```

#### Beispiel: Bug-Fix

```
Änderungen:
└── Handler: PSD (Bug-Fix)

Nicht geändert:
├── Handler: JPG
├── Handler: SVG
└── Handler: PNG
```

---

## 5. Kommunikation (Events)

### 5.1 Grundprinzip

Extensions kommunizieren nicht direkt miteinander. Stattdessen kommunizieren sie über Events.

#### Ablauf

1. Eine Extension **veröffentlicht** ein Event (was ist passiert?)
2. Der Kernel **verteilt** das Event an interessierte Extensions
3. Andere Extensions **reagieren** auf das Event

#### Warum Events?

| Vorteil | Beschreibung |
|---------|--------------|
| **Entkopplung** | Extensions kennen sich nicht gegenseitig |
| **Flexibilität** | Neue Extensions können auf bestehende Events reagieren |
| **Ausfallsicherheit** | Wenn eine Extension ausfällt, funktionieren andere weiter |
| **Skalierbarkeit** | Extensions können unabhängig voneinander skaliert werden |

#### Beispiel

```
Extension: Assets                    Extension: Vorschau-Generator
      │                                      │
      │ 1. Asset hochgeladen                 │
      │                                      │
      │ 2. Event veröffentlichen:            │
      │    "asset.uploaded"                  │
      │         │                            │
      │         ▼                            │
      │    ┌─────────┐                       │
      │    │Event Bus│                       │
      │    └─────────┘                       │
      │         │                            │
      │         │ 3. Event verteilen         │
      │         └───────────────────────────►│
      │                                      │
      │                           4. Vorschau generieren
      │                                      │
      │                           5. Event veröffentlichen:
      │◄─────────────────────────────────────│
      │    "asset.previews_generated"        │
      │                                      │
      │ 6. Metadaten aktualisieren           │
```

---

### 5.2 Event-Struktur

Jedes Event hat eine einheitliche Struktur.

#### Felder

| Feld | Beschreibung |
|------|--------------|
| **event_id** | Eindeutige ID des Events |
| **event_type** | Art des Events (z.B. "asset.uploaded") |
| **version** | Version der Event-Struktur |
| **timestamp** | Zeitpunkt der Entstehung |
| **source** | Extension die das Event veröffentlicht hat |
| **tenant_id** | Tenant zu dem das Event gehört |
| **correlation_id** | ID um zusammenhängende Events zu verfolgen |
| **payload** | Die eigentlichen Daten (Event-spezifisch) |

#### Beispiel

```json
{
  "event_id": "evt-123-456-789",
  "event_type": "asset.uploaded",
  "version": "1.0",
  "timestamp": "2025-01-13T14:30:00Z",
  "source": "mkg-extension-assets",
  "tenant_id": "tenant-abc",
  "correlation_id": "req-987-654-321",
  "payload": {
    "asset_id": "asset-123",
    "filename": "produktbild.psd",
    "format": "psd",
    "size_bytes": 15000000
  }
}
```

#### Namenskonvention für event_type

```
{entity}.{action}
```

| Beispiel | Beschreibung |
|----------|--------------|
| `asset.uploaded` | Ein Asset wurde hochgeladen |
| `asset.deleted` | Ein Asset wurde gelöscht |
| `entity.created` | Eine Entity wurde erstellt |
| `entity.updated` | Eine Entity wurde aktualisiert |
| `workflow.started` | Ein Workflow wurde gestartet |
| `workflow.completed` | Ein Workflow wurde abgeschlossen |

---

### 5.3 Subscriptions

Eine Subscription ist eine Anmeldung einer Extension für bestimmte Events.

#### Funktionsweise

1. Extension meldet sich beim Event Bus für einen Event-Typ an
2. Event Bus merkt sich die Subscription
3. Wenn ein passendes Event eintrifft, leitet der Event Bus es an die Extension weiter

#### Eigenschaften

| Eigenschaft | Beschreibung |
|-------------|--------------|
| **Event-Typ** | Auf welchen Event-Typ reagiert werden soll |
| **Filter** | Optionale Einschränkung auf bestimmte Payload-Werte |
| **Ziel** | Wohin das Event geliefert werden soll |

#### Beispiel ohne Filter

```
Extension: Vorschau-Generator
Subscription: "asset.uploaded"

→ Empfängt alle Events vom Typ "asset.uploaded"
```

#### Beispiel mit Filter

```
Extension: Vorschau-Generator
Subscription: "asset.uploaded"
Filter: format IN ["psd", "jpg", "png", "svg"]

→ Empfängt nur Events für diese Dateiformate
```

#### Mehrere Subscriptions

Eine Extension kann mehrere Subscriptions haben:

```
Extension: Audit-Log

Subscriptions:
- "asset.uploaded"
- "asset.deleted"
- "entity.created"
- "entity.updated"
- "entity.deleted"

→ Protokolliert alle relevanten Änderungen
```

---

## 6. Repository-Struktur

### 6.1 Übersicht

Jede Komponente der Plattform liegt in einem eigenen Repository.

#### Kategorien

| Kategorie | Beschreibung | Präfix |
|-----------|--------------|--------|
| **Kernel** | Kern-Komponenten der Plattform | `mkg-kernel-` |
| **Extension** | Unabhängige Module mit Business-Logik | `mkg-extension-` |
| **Library** | Gemeinsam genutzte Bibliotheken | `mkg-lib-` |
| **Template** | Vorlagen für neue Repositories | `mkg-template-` |
| **Infrastructure** | Terraform und AWS-Konfiguration | `mkg-infrastructure-` |
| **Documentation** | Dokumentation | `mkg-docs-` |

#### Beispiel-Struktur

```
GitHub Organization: mkg-machines
│
├── Kernel
│   ├── mkg-kernel-entity
│   ├── mkg-kernel-schema
│   ├── mkg-kernel-eventbus
│   ├── mkg-kernel-auth
│   └── mkg-kernel-gateway
│
├── Extensions (Core)
│   ├── mkg-extension-assets
│   ├── mkg-extension-preview-generator
│   ├── mkg-extension-validation
│   └── mkg-extension-workflow
│
├── Extensions (Tenant)
│   └── mkg-extension-tenant-xyz-export
│
├── Libraries
│   ├── mkg-lib-events
│   ├── mkg-lib-testing
│   └── mkg-lib-common
│
├── Templates
│   └── mkg-template-extension
│
├── Infrastructure
│   ├── mkg-infrastructure-org
│   └── mkg-infrastructure-shared
│
└── Documentation
    └── mkg-docs-architecture
```

---

### 6.2 Abhängigkeitsregeln

Klare Regeln definieren, welches Repository welches andere als Dependency nutzen darf.

#### Regeln

| Repository | Darf nutzen | Darf NICHT nutzen |
|------------|-------------|-------------------|
| **Kernel** | Libraries | Extensions |
| **Extension** | Libraries | Kernel-Code, andere Extensions |
| **Library** | Andere Libraries | Kernel, Extensions |

#### Erklärung

**Extension darf Libraries nutzen:**
```
mkg-extension-assets
└── nutzt: mkg-lib-events (um Events zu veröffentlichen)
└── nutzt: mkg-lib-common (für gemeinsame Typen)
```

**Extension darf Kernel-Code NICHT nutzen:**
```
mkg-extension-assets
└── nutzt NICHT: mkg-kernel-entity (kein direkter Import)
└── stattdessen: Zugriff über Kernel-APIs (HTTP)
```

**Extension darf andere Extensions NICHT nutzen:**
```
mkg-extension-assets
└── nutzt NICHT: mkg-extension-validation (kein direkter Import)
└── stattdessen: Kommunikation über Events
```

#### Warum diese Regeln?

| Regel | Grund |
|-------|-------|
| Extensions nutzen keinen Kernel-Code | Kernel kann sich intern ändern ohne Extensions anzupassen |
| Extensions nutzen keine anderen Extensions | Extensions bleiben unabhängig voneinander |
| Libraries nutzen keinen Kernel/Extensions | Libraries bleiben wiederverwendbar |

---

## 7. Entwickler-Guide

### 7.1 Neue Extension erstellen

Schritt-für-Schritt Anleitung zur Erstellung einer neuen Extension.

#### Schritt 1: Repository erstellen

```bash
# Template klonen
gh repo create mkg-machines/mkg-extension-{name} \
  --template mkg-machines/mkg-template-extension \
  --private

# Repository lokal klonen
git clone git@github.com:mkg-machines/mkg-extension-{name}.git
cd mkg-extension-{name}
```

#### Schritt 2: Extension konfigurieren

- Repository-Name anpassen
- Beschreibung hinzufügen
- Event-Subscriptions definieren

#### Schritt 3: Handler implementieren

- Handler für jede Variante erstellen
- Jeder Handler in eigener Datei
- Jeder Handler mit eigenen Tests

#### Schritt 4: Testen

```bash
# Abhängigkeiten installieren
make install

# Tests ausführen
make test

# Lokal starten
make local
```

#### Schritt 5: Deployment

```bash
# Feature-Branch erstellen
git checkout -b feat/initial-implementation

# Änderungen committen
git add .
git commit -m "feat: initial implementation"

# Push und Pull Request erstellen
git push -u origin feat/initial-implementation
```

Weitere Details zur Entwicklung befinden sich in der **mkg-template-extension**.

---

### 7.2 Checkliste vor Deployment

Vor jedem Deployment muss folgende Checkliste erfüllt sein:

#### Code

- [ ] Alle Handler haben eigene Tests
- [ ] Alle Tests sind erfolgreich
- [ ] Code Review abgeschlossen
- [ ] Keine Abhängigkeiten zu anderen Extensions
- [ ] Keine direkten Imports von Kernel-Code

#### Dokumentation

- [ ] README aktualisiert
- [ ] Event-Subscriptions dokumentiert
- [ ] Veröffentlichte Events dokumentiert
- [ ] APIs dokumentiert (falls vorhanden)

#### CI/CD

- [ ] CI Pipeline ist erfolgreich (Lint, Test, Security)
- [ ] Commit-Messages folgen Conventional Commits

#### Review

- [ ] Pull Request erstellt
- [ ] Code Review durch mindestens einen Entwickler
- [ ] Feedback eingearbeitet

---

## 8. Deployment

### 8.1 Environments

Die Plattform nutzt drei Environments:

| Environment | Zweck | Deployment |
|-------------|-------|------------|
| **DEV** | Entwicklung und erste Tests | Automatisch bei Merge in `main` |
| **STAGE** | Qualitätssicherung und Abnahme | Manuell (Tag auswählen) |
| **PROD** | Produktivbetrieb | Manuell (Tag auswählen + Approval) |

#### DEV

- Automatisches Deployment bei jedem Merge in `main`
- Zum Testen neuer Features
- Kann instabil sein

#### STAGE

- Manuelles Deployment eines gewählten Tags
- Zum Testen vor Produktivsetzung
- Sollte stabil sein

#### PROD

- Manuelles Deployment eines gewählten Tags
- Erfordert Approval durch Team Lead
- Muss stabil sein

---

### 8.2 Deployment-Flow

Der Weg vom Code bis zur Produktion folgt einem festen Ablauf.

#### Übersicht

```
Feature-Branch → Pull Request → Main → Tag → STAGE → PROD
```

#### Ablauf im Detail

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. Feature-Branch erstellen                                         │
│    git checkout -b feat/neue-funktion                               │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 2. Entwickeln und Committen                                         │
│    git commit -m "feat: neue Funktion hinzugefügt"                  │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 3. Pull Request erstellen                                           │
│    - CI läuft automatisch (Lint, Test, Security)                   │
│    - Code Review durch Kollegen                                     │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 4. Merge in Main                                                    │
│    - Automatisches Deployment nach DEV                              │
│    - Automatische Tag-Erstellung (z.B. v1.3.0)                     │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 5. Testen in DEV                                                    │
│    - Funktioniert alles wie erwartet?                              │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 6. Deployment nach STAGE                                            │
│    - Manuell auslösen                                              │
│    - Tag auswählen (z.B. v1.3.0)                                   │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 7. Testen in STAGE                                                  │
│    - Abnahme durch QA oder Fachbereich                             │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 8. Deployment nach PROD                                             │
│    - Manuell auslösen                                              │
│    - Tag auswählen (z.B. v1.3.0)                                   │
│    - Approval durch Team Lead erforderlich                         │
└─────────────────────────────────────────────────────────────────────┘
```

---

### 8.3 Versionierung

Alle Repositories folgen Semantic Versioning mit automatischer Tag-Erstellung.

#### Semantic Versioning

Format: **MAJOR.MINOR.PATCH** (z.B. v1.3.0)

| Teil | Wann erhöhen | Beispiel |
|------|--------------|----------|
| **MAJOR** | Breaking Changes | v1.0.0 → v2.0.0 |
| **MINOR** | Neue Features (rückwärtskompatibel) | v1.0.0 → v1.1.0 |
| **PATCH** | Bugfixes | v1.0.0 → v1.0.1 |

#### Conventional Commits

Die Commit-Message bestimmt die Versionserhöhung:

| Prefix | Beschreibung | Versionserhöhung |
|--------|--------------|------------------|
| `feat:` | Neues Feature | MINOR |
| `fix:` | Bugfix | PATCH |
| `feat!:` oder `fix!:` | Breaking Change | MAJOR |
| `docs:` | Dokumentation | Keine |
| `refactor:` | Code-Umbau ohne Funktionsänderung | Keine |
| `test:` | Tests hinzufügen/ändern | Keine |
| `chore:` | Wartungsarbeiten | Keine |

#### Beispiele

```
git commit -m "feat: neuen Handler für PNG hinzugefügt"
→ Version: v1.2.0 → v1.3.0

git commit -m "fix: Fehler bei der Vorschau-Generierung behoben"
→ Version: v1.3.0 → v1.3.1

git commit -m "feat!: Event-Struktur geändert"
→ Version: v1.3.1 → v2.0.0
```

#### Automatisierung

- Bei Merge in `main` wird automatisch ein Tag erstellt
- Die Version wird aus den Commit-Messages berechnet
- Ein Changelog wird automatisch generiert

---

*Dieses Dokument ist die verbindliche Architektur-Grundlage für die MKG Platform. Alle technischen Entscheidungen müssen mit diesen Prinzipien übereinstimmen.*