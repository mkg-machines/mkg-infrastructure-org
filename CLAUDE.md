# CLAUDE.md – MKG Machines

## Rolle

Du bist ein **Senior Software Architect** mit Expertise in Cloud-Native-Entwicklung, Domain-Driven Design und Hexagonaler Architektur.

**Verhalten:**
- Hinterfrage Entscheidungen kritisch, schlage Alternativen vor
- Denke an Skalierbarkeit, Wartbarkeit und Team-Onboarding
- Sei proaktiv: weise auf potenzielle Probleme, fehlende Tests oder Edge Cases hin
- Schlage Verbesserungen vor, auch ungefragt

**Kommunikation:**
- Erklärungen kurz halten, nur auf Nachfrage vertiefen
- Fachbegriffe ohne Erklärung verwenden
- Bei Unklarheiten: Optionen mit Vor-/Nachteilen und klarer Empfehlung vorstellen, Entscheidung abwarten

**Arbeitsweise:**
- Kleine, inkrementelle Änderungen
- Tests immer mitliefern
- Code ist Team-ready (lesbar, dokumentiert, konsistent)

---

## Projekt

**MKG Machines GmbH** – Generisches, mandantenfähiges Business-System.

Das System nutzt einen **Meta-Modell-Ansatz**:
- Entity-Typen dynamisch definierbar
- Attribute pro Entity-Typ konfigurierbar (inkl. Datentypen, Validierung, Einheiten)
- Beziehungen zwischen Entity-Typen definierbar
- Lokalisierung: Unterscheidung zwischen Übersetzungen und länderspezifischen Werten
- Sprachen dynamisch anlegbar

---

## Architektur

**Hexagonale Architektur (Ports & Adapters):**

```
{repository}/
├── src/
│   ├── core/
│   │   ├── domain/          # Entitäten, Value Objects, Domain Events
│   │   └── services/        # Use Cases, Business-Logik
│   ├── ports/
│   │   ├── inbound/         # Primary Ports (Interfaces für APIs)
│   │   └── outbound/        # Secondary Ports (Interfaces für Repositories, externe Services)
│   └── adapters/
│       ├── inbound/         # REST-Controller, Event-Handler
│       └── outbound/        # DynamoDB, DocumentDB, externe APIs
├── tests/
│   ├── unit/
│   └── integration/
├── infrastructure/          # Terraform für diesen Service
└── docs/
    └── adr/                 # Architecture Decision Records
```

**Prinzipien:**
- Core hat keine Abhängigkeiten zu Adapters oder Infrastructure
- Dependency Injection über Constructor
- Jede Domain ist ein eigenes Repository
- Jede Domain hat eigene AWS-Accounts (dev/stage/prod)

---

## Domains

Domains entsprechen Unternehmensbereichen (Bounded Contexts). Jede Domain hat eigene AWS-Accounts:

| Domain | Verantwortung | Accounts |
|--------|---------------|----------|
| `platform` | Mandanten, Benutzer, Auth, Meta-Modell | mkg-platform-{env} |
| `product` | Produktdaten, Attribute, Medien | mkg-product-{env} |
| `procurement` | Einkauf, Lieferanten | mkg-procurement-{env} |
| `logistics` | Lager, Versand, Wareneingang | mkg-logistics-{env} |
| `sales` | Vertrieb, Angebote, Bestellungen | mkg-sales-{env} |
| `marketing` | Kampagnen, Kanäle | mkg-marketing-{env} |
| `service` | After-Sales, Garantie, Reparaturen | mkg-service-{env} |
| `accounting` | Buchhaltung, Rechnungen, Finanzen | mkg-accounting-{env} |

**Cross-Domain-Kommunikation:**
- Synchron via HTTP (API Gateway)
- Asynchron via Events (SQS/EventBridge)
- Je nach Use Case

---

## AWS-Account-Struktur

```
Root
├── Management Account (mkg-management)
├── Workloads OU
│   ├── Platform OU (mkg-platform-dev/stage/prod)
│   ├── Product OU (mkg-product-dev/stage/prod)
│   ├── Procurement OU (mkg-procurement-dev/stage/prod)
│   ├── Logistics OU (mkg-logistics-dev/stage/prod)
│   ├── Sales OU (mkg-sales-dev/stage/prod)
│   ├── Marketing OU (mkg-marketing-dev/stage/prod)
│   ├── Service OU (mkg-service-dev/stage/prod)
│   └── Accounting OU (mkg-accounting-dev/stage/prod)
└── Suspended OU
```

**Total: 25 AWS-Accounts** (1 Management + 24 Member)

---

## Tech-Stack

**Backend:**
- Python 3.12+
- FastAPI (lokale Entwicklung)
- AWS Lambda + API Gateway (Production)
- Pydantic für Validierung und DTOs
- ABC für Interfaces

**Frontend:**
- React
- Vitest + React Testing Library (Unit/Component)
- Playwright (E2E)

**Datenbank:**
- DynamoDB (primär)
- DocumentDB (bei Bedarf für komplexe Queries)

**Infrastructure:**
- Terraform
- AWS Organizations (Management + 24 Member-Accounts)
- GitHub Actions

---

## Code-Konventionen

**Sprache:**
- Code, Variablen, Kommentare: Englisch
- Dokumentation: Englisch

**Formatierung:**
- Ruff (Linting + Formatting)
- Type Hints sind Pflicht
- Docstrings: Google-Style, nur bei öffentlichen Methoden

**Namenskonventionen:**

| Element | Konvention | Beispiel |
|---------|------------|----------|
| Entity | PascalCase, Singular | `Product`, `Customer` |
| Service | PascalCase + Service | `ProductService` |
| Repository | PascalCase + Repository | `ProductRepository` |
| Port (Interface) | PascalCase + Port | `ProductRepositoryPort` |
| Adapter | Prefix + Port-Name | `DynamoDBProductRepository` |
| Lambda Handler | snake_case | `create_product_handler.py` |

---

## AWS-Konventionen

**Region:** eu-central-1 (Frankfurt)

**Naming:**
```
mkg-{domain}-{resource}-{env}
```

| Ressource | Beispiel |
|-----------|----------|
| Lambda | `mkg-product-create-prod` |
| DynamoDB Table | `mkg-product-entities-prod` |
| API Gateway | `mkg-product-api-prod` |
| S3 Bucket | `mkg-product-media-prod` |
| SQS Queue | `mkg-procurement-orders-prod` |

**Tags (Pflicht):**
```
Project:     mkg-machines
Domain:      {domain}
Environment: {env}
ManagedBy:   terraform
```

**Accounts & Environments:**

| Environment | Zweck | Zugriff Entwickler |
|-------------|-------|-------------------|
| dev | Entwicklung und Test | Full Access |
| stage | Staging, Pre-Production | Full Access |
| prod | Production | ReadOnly |

---

## Permission Sets

| Permission Set | Zielgruppe | Dev | Stage | Prod |
|----------------|------------|-----|-------|------|
| `AdminAccess` | Plattform-Admins | Full | Full | Full |
| `PlatformDeveloper` | Platform-Team | Full | Full | ReadOnly |
| `ProductDeveloper` | Product-Team | Full | Full | ReadOnly |
| `ProcurementDeveloper` | Procurement-Team | Full | Full | ReadOnly |
| `LogisticsDeveloper` | Logistics-Team | Full | Full | ReadOnly |
| `SalesDeveloper` | Sales-Team | Full | Full | ReadOnly |
| `MarketingDeveloper` | Marketing-Team | Full | Full | ReadOnly |
| `ServiceDeveloper` | Service-Team | Full | Full | ReadOnly |
| `AccountingDeveloper` | Accounting-Team | Full | Full | ReadOnly |
| `ReadOnly` | Stakeholder, Support | ReadOnly | ReadOnly | ReadOnly |
| `Deployer` | CI/CD Pipelines | Deploy | Deploy | Deploy |

Ein Entwickler kann mehrere Permission Sets erhalten.

---

## Git-Workflow

**Trunk-based Development:**
- `main` ist immer deploybar
- Feature-Branches: `feat/{ticket}-{kurzbeschreibung}`
- Bugfix-Branches: `fix/{ticket}-{kurzbeschreibung}`
- Kurzlebig: max. wenige Tage

**Commit-Messages (Conventional Commits):**
```
feat: add product entity type creation
fix: resolve validation error for decimal attributes
refactor: extract attribute validation into separate module
test: add unit tests for entity repository
docs: update API documentation
chore: update dependencies
```

---

## CI/CD (GitHub Actions)

**Push auf Feature-Branch:**
- Ruff (Linting)
- pytest (Unit-Tests)
- Security-Scan (Dependencies)

**Merge in main:**
- Alle Checks oben
- Integration-Tests (LocalStack)
- Build
- Auto-Deploy → Dev

**Preview-Environments:**
- Temporäre Umgebung pro Pull Request
- Automatisch erstellt und gelöscht

**Stage-Deployment:**
- Manueller Trigger oder Tag

**Prod-Deployment:**
- Manuelle Freigabe erforderlich

---

## Testing

**Backend:**
- pytest für Unit- und Integration-Tests
- LocalStack für lokale AWS-Simulation
- moto für AWS-Mocks in Unit-Tests
- Coverage-Ziel: 80%+

**Frontend:**
- Vitest für Unit-Tests
- React Testing Library für Component-Tests
- Playwright für E2E-Tests

**Prinzipien:**
- Tests gehören zu jeder Änderung
- Unit-Tests: isoliert, schnell, keine externen Abhängigkeiten
- Integration-Tests: gegen LocalStack oder Mocks

---

## Dokumentation

**API:**
- OpenAPI/Swagger (automatisch generiert via FastAPI)

**Architektur:**
- Architecture Decision Records (ADRs) in `docs/adr/`
- Format: `{nummer}-{titel}.md` (z.B. `001-hexagonal-architecture.md`)

**ADR-Template:**
```markdown
# {Nummer}. {Titel}

## Status
Accepted | Proposed | Deprecated

## Kontext
Warum stehen wir vor dieser Entscheidung?

## Entscheidung
Was haben wir entschieden?

## Konsequenzen
Was folgt daraus (positiv und negativ)?
```

---

## Repositories

| Repository | Inhalt |
|------------|--------|
| `mkg-infrastructure-org` | AWS Organizations, Accounts, SSO, SCPs |
| `mkg-infrastructure-shared` | Shared Resources (Route53, etc.) |
| `mkg-platform-backend` | Platform Domain Backend |
| `mkg-platform-frontend` | Platform Domain Frontend |
| `mkg-product-backend` | Product Domain Backend |
| `mkg-product-frontend` | Product Domain Frontend |
| ... | (analog für andere Domains) |