# RapForge 🎤

> A full-stack SAP Cloud Application Programming (CAP) project for managing rap battles, artists, and live voting — built on SAP BTP with Fiori Elements UI, XSUAA authentication, and CI/CD via GitHub Actions.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Data Model](#data-model)
- [Service Layer](#service-layer)
- [Authentication & Authorization](#authentication--authorization)
- [Fiori Elements UI](#fiori-elements-ui)
- [CI/CD Pipeline](#cicd-pipeline)
- [Local Development](#local-development)
- [Running Tests](#running-tests)
- [BTP Deployment](#btp-deployment)
- [Tech Stack](#tech-stack)

---

## Overview

**RapForge** is a learning project that demonstrates the full SAP BTP development stack:

- Model-driven development with **CDS (Core Data Services)**
- RESTful OData APIs via **SAP CAP Node.js**
- Auto-generated **Fiori Elements** UI (zero custom HTML/CSS)
- Role-based access control via **XSUAA**
- Test-driven development with **Jest + @cap-js/cds-test**
- CI/CD with **GitHub Actions**
- Cloud deployment on **SAP BTP Cloud Foundry**

---

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        SAP BTP Trial                            │
│                                                                 │
│  ┌──────────────────┐         ┌──────────────────────────────┐  │
│  │   SAP Build      │         │     Cloud Foundry Runtime    │  │
│  │   Work Zone      │────────▶│                              │  │
│  │  (Fiori Launchpad│  HTTP   │   ┌──────────────────────┐   │  │
│  │   + App Host)    │         │   │   RapForge CAP App   │   │  │
│  └──────────────────┘         │   │   (Node.js / CDS)    │   │  │
│                                │   └──────────┬───────────┘   │  │
│  ┌──────────────────┐          │              │               │  │
│  │   XSUAA          │◀─────────│   Auth JWT   │               │  │
│  │   (Auth Service) │          │              │               │  │
│  └──────────────────┘          │   ┌──────────▼───────────┐   │  │
│                                │   │   SAP HANA Cloud     │   │  │
│                                │   │   (Database)         │   │  │
│                                │   └──────────────────────┘   │  │
│                                └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Request Flow

```
Browser / Fiori UI
       │
       │  HTTPS
       ▼
┌─────────────┐     JWT Token     ┌─────────────┐
│  Approuter  │──────────────────▶│   XSUAA     │
│  (optional) │◀──────────────────│  (Auth)     │
└──────┬──────┘   Token validated └─────────────┘
       │
       │  OData / REST
       ▼
┌─────────────────────────────────────────┐
│           CAP Node.js Runtime           │
│                                         │
│  ┌─────────────┐   ┌─────────────────┐  │
│  │  CDS Model  │   │  Auth Middleware │  │
│  │  (schema)   │   │  @requires check│  │
│  └──────┬──────┘   └────────┬────────┘  │
│         │                   │           │
│         ▼                   ▼           │
│  ┌──────────────────────────────────┐   │
│  │     RapBattleService Handler     │   │
│  │  (TypeScript business logic)     │   │
│  │                                  │   │
│  │  before → validate               │   │
│  │  on     → execute                │   │
│  │  after  → side effects           │   │
│  └───────────────────┬──────────────┘   │
│                      │                  │
└──────────────────────┼──────────────────┘
                       │  SQL
                       ▼
              ┌─────────────────┐
              │  SQLite (dev)   │
              │  HANA (prod)    │
              └─────────────────┘
```

### CAP Golden Triangle

```
         ┌─────────────────────────────┐
         │         CDS Model           │
         │  db/schema.cds              │
         │  (Entities, Associations)   │
         └──────────┬──────────────────┘
                    │ defines
          ┌─────────┴──────────┐
          │                    │
          ▼                    ▼
┌──────────────────┐  ┌──────────────────────┐
│   Service Layer  │  │      Database        │
│  srv/*.cds       │  │  SQLite (dev)        │
│  srv/*.ts        │  │  HANA Cloud (prod)   │
│  (OData API +    │  │  Auto-deployed from  │
│   Business Logic)│  │  CDS model           │
└──────────────────┘  └──────────────────────┘
          │
          │ consumed by
          ▼
┌──────────────────────────────────────┐
│          Fiori Elements UI           │
│  app/battles/manifest.json           │
│  app/battles/annotations.cds         │
│  (Zero custom HTML — driven by CDS)  │
└──────────────────────────────────────┘
```

---

## Project Structure

```
RapForge/
│
├── .github/
│   └── workflows/
│       └── ci.yml              ← GitHub Actions CI/CD pipeline
│
├── app/                        ← Fiori Elements UI
│   ├── index.cds               ← Registers all app annotations
│   └── battles/
│       ├── Component.js        ← UI5 app entry point
│       ├── manifest.json       ← App config (routing, OData source)
│       ├── annotations.cds     ← Drives the entire UI layout
│       └── i18n/
│           └── i18n.properties ← UI text labels
│
├── db/                         ← Data domain
│   ├── schema.cds              ← Entity definitions (Artists, Battles, Votes)
│   ├── data-model.cds          ← Model extensions and annotations
│   └── data/
│       ├── rap.battle-Artists.csv   ← Seed data
│       └── rap.battle-Battles.csv   ← Seed data
│
├── srv/                        ← Service layer
│   ├── rap-battle-service.cds  ← OData service definition + auth rules
│   └── rap-battle-service.ts   ← TypeScript business logic handlers
│
├── test/
│   └── rap-battle.test.js      ← Jest integration tests
│
├── xs-security.json            ← XSUAA roles and scopes for BTP
├── tsconfig.json               ← TypeScript configuration
└── package.json                ← Dependencies and scripts
```

---

## Data Model

### Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ┌──────────────┐           ┌──────────────────────────┐  │
│   │   Artists    │           │        Battles           │  │
│   │──────────────│           │──────────────────────────│  │
│   │ ID (PK)      │           │ ID (PK)                  │  │
│   │ name         │           │ title                    │  │
│   │ stageName    │           │ date                     │  │
│   │ city         │           │ venue                    │  │
│   │ bio          │           │ status (upcoming/        │  │
│   │ createdAt    │           │         ongoing/         │  │
│   │ createdBy    │           │         completed)       │  │
│   └──────┬───────┘           └───────────┬──────────────┘  │
│          │                               │                 │
│          │         ┌─────────────────────┘                 │
│          │         │                                       │
│          ▼         ▼                                       │
│   ┌──────────────────────────┐                             │
│   │   BattleParticipants     │   (many-to-many link)       │
│   │──────────────────────────│                             │
│   │ ID (PK)                  │                             │
│   │ battle_ID (FK)           │                             │
│   │ artist_ID (FK)           │                             │
│   │ score                    │                             │
│   └──────────────────────────┘                             │
│                                                             │
│   ┌──────────────────────────┐                             │
│   │         Votes            │                             │
│   │──────────────────────────│                             │
│   │ ID (PK)                  │                             │
│   │ battle_ID (FK)───────────┼──▶ Battles                 │
│   │ artist_ID (FK)───────────┼──▶ Artists                 │
│   │ voter                    │                             │
│   │ comment                  │                             │
│   │ createdAt                │                             │
│   └──────────────────────────┘                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Key CDS Features Used

| Feature | Description |
|---|---|
| `cuid` | Auto-generates UUID primary keys |
| `managed` | Auto-fills `createdAt`, `createdBy`, `modifiedAt`, `modifiedBy` |
| `Association` | Foreign key relationships (navigable in OData) |
| `Composition` | Parent-owns-child (cascading operations) |
| `String enum` | Constrained value set for `status` field |

---

## Service Layer

### OData Endpoints

Base URL: `/api/rap-battle`

| Method | Endpoint | Role Required | Description |
|---|---|---|---|
| GET | `/Artists` | Viewer | List all artists |
| POST | `/Artists` | Admin | Create artist |
| GET | `/Battles` | Viewer | List all battles |
| POST | `/Battles` | Admin | Create battle |
| GET | `/BattleParticipants` | Viewer | List participants |
| GET | `/Votes` | Viewer | List votes |
| POST | `/Votes` | Voter | Cast a vote |
| POST | `/castVote` | Voter | Cast vote (with validation) |
| GET | `/getLeaderboard(battleId=...)` | Viewer | Battle leaderboard |
| GET | `/$metadata` | Any | OData metadata |

### Handler Lifecycle

```
HTTP Request
     │
     ▼
┌──────────────────────────────────────────┐
│              CAP Middleware              │
│  Auth check (@requires) → 401/403        │
└─────────────────┬────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────┐
│           BEFORE handlers                │
│  - Validate battle exists                │
│  - Check battle status (not completed)   │
│  - Check for duplicate votes             │
└─────────────────┬────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────┐
│            ON handlers                   │
│  - castVote: validate + insert           │
│  - getLeaderboard: aggregate query       │
└─────────────────┬────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────┐
│           AFTER handlers                 │
│  - Update participant score after vote   │
└─────────────────┬────────────────────────┘
                  │
                  ▼
            HTTP Response
```

---

## Authentication & Authorization

### Role Hierarchy

```
┌─────────────────────────────────────────────────┐
│                    Admin                        │
│  ┌───────────────────────────────────────────┐  │
│  │                  Voter                    │  │
│  │  ┌─────────────────────────────────────┐  │  │
│  │  │              Viewer                 │  │  │
│  │  │  - Read Artists                     │  │  │
│  │  │  - Read Battles                     │  │  │
│  │  │  - Read Votes                       │  │  │
│  │  │  - View Leaderboard                 │  │  │
│  │  └─────────────────────────────────────┘  │  │
│  │  + Cast votes (castVote action)            │  │
│  └───────────────────────────────────────────┘  │
│  + Create/Edit Artists, Battles                 │
└─────────────────────────────────────────────────┘
```

### Auth Flow (Production on BTP)

```
User opens Fiori App
        │
        ▼
   Approuter
        │ redirect if no session
        ▼
   XSUAA Login Page
        │ credentials
        ▼
   JWT Token issued
   (contains scopes:
    RapForge.Viewer etc.)
        │
        ▼
   CAP validates JWT
   via @sap/xssec
        │
        ▼
   @requires check
   on each endpoint
        │
     ┌──┴──┐
     │     │
   Pass   Fail
     │     │
     ▼     ▼
  200 OK  403 Forbidden
```

### Local Development Auth

Locally, CAP uses **mocked auth** — no XSUAA needed:

```bash
# Access as Viewer
curl -u viewer:viewer http://localhost:4004/api/rap-battle/Battles

# Access as Admin (configure mock users in .cdsrc.json)
curl -u admin:admin http://localhost:4004/api/rap-battle/Artists
```

---

## Fiori Elements UI

### UI Architecture

```
annotations.cds (YOU write this)
        │
        │ drives
        ▼
┌──────────────────────────────────────────────┐
│           Fiori Elements Runtime             │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │          List Report Page              │  │
│  │                                        │  │
│  │  [Filter Bar: Status | Date]           │  │
│  │  ┌──────┬────────────┬──────┬───────┐  │  │
│  │  │Title │    Date    │Venue │Status │  │  │
│  │  ├──────┼────────────┼──────┼───────┤  │  │
│  │  │JHB.. │ 2026-08-20 │ ..   │ongoing│  │  │
│  │  │CPT.. │ 2026-09-15 │ ..   │upcoming│ │  │
│  │  └──────┴────────────┴──────┴───────┘  │  │
│  └──────────────────┬─────────────────────┘  │
│                     │ click row              │
│                     ▼                        │
│  ┌────────────────────────────────────────┐  │
│  │           Object Page                  │  │
│  │                                        │  │
│  │  [Header: Battle Title | Venue]        │  │
│  │                                        │  │
│  │  [Tab: Battle Info]                    │  │
│  │  [Tab: Participants] ← sub-table       │  │
│  │  [Tab: Votes]        ← sub-table       │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

**Zero custom HTML/CSS/JavaScript written** — the entire UI is generated from `annotations.cds`.

---

## CI/CD Pipeline

```
Developer pushes code
         │
         ▼
┌────────────────────────────────────────────────┐
│              GitHub Actions                    │
│                                                │
│  Trigger: push to master / pull_request        │
│                                                │
│  ┌──────────────────────────────────────────┐  │
│  │            Job 1: test                   │  │
│  │                                          │  │
│  │  1. checkout code                        │  │
│  │  2. setup Node.js 22                     │  │
│  │  3. npm ci                               │  │
│  │  4. cds compile check                    │  │
│  │  5. npm test (Jest 8 tests)              │  │
│  └──────────────────┬───────────────────────┘  │
│                     │ on master only            │
│                     ▼                          │
│  ┌──────────────────────────────────────────┐  │
│  │          Job 2: build-mta               │  │
│  │                                          │  │
│  │  1. npm ci                               │  │
│  │  2. cds add mta                          │  │
│  │  3. mbt build → RapForge.mtar            │  │
│  │  4. upload artifact (7 day retention)    │  │
│  └──────────────────────────────────────────┘  │
└────────────────────────────────────────────────┘
         │
         ▼ (future: add deploy job)
  CF Push to BTP Trial
```

---

## Local Development

### Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| Node.js | >= 18 | Runtime |
| `@sap/cds-dk` | >= 10 | CAP CLI |
| `mbt` | >= 1.2 | MTA build tool |
| CF CLI | >= 8 | BTP deployment |
| Git | any | Version control |

### Install & Run

```bash
# Clone the repo
git clone https://github.com/SunilV02/RapForge.git
cd RapForge

# Install dependencies
npm install

# Start local dev server (live reload)
cds watch
```

Open `http://localhost:4004` in your browser.

### Available URLs (local)

| URL | Description |
|---|---|
| `http://localhost:4004` | CAP welcome page + app tile |
| `http://localhost:4004/api/rap-battle` | OData service root |
| `http://localhost:4004/api/rap-battle/Artists` | Artists JSON |
| `http://localhost:4004/api/rap-battle/Battles` | Battles JSON |
| `http://localhost:4004/api/rap-battle/$metadata` | OData XML metadata |

---

## Running Tests

```bash
npm test
```

### Test Coverage

| Test | What It Verifies |
|---|---|
| GET /Artists returns seeded artists | CSV seed data loads correctly |
| GET /Artists returns correct fields | Schema shape is correct |
| POST /Artists creates a new artist | Write operations work |
| GET /Battles all have valid status | Enum constraints enforced |
| GET /Battles returns seeded battles | Battle data loads correctly |
| POST /Battles creates a new battle | Battle creation works |
| POST /Votes creates a vote | Voting happy path works |
| POST /Votes blocks duplicate vote | 409 guard logic works |

CAP's `cds.test()` spins up a **real HTTP server + real in-memory SQLite DB** per test run — no mocking.

---

## BTP Deployment

### Prerequisites on BTP Trial

1. BTP Trial account at [trial.btp.cloud.sap](https://account.hanatrial.ondemand.com)
2. Cloud Foundry environment enabled
3. SAP HANA Cloud instance running
4. XSUAA service instance created

### Deploy Steps

```bash
# 1. Login to Cloud Foundry
cf login -a https://api.cf.<region>.hana.ondemand.com

# 2. Add MTA deployment config
cds add mta

# 3. Add HANA support
cds add hana

# 4. Build the MTA archive
mbt build --mtar RapForge.mtar

# 5. Deploy to BTP
cf deploy mta_archives/RapForge.mtar
```

### BTP Services Created on Deploy

```
RapForge (MTA)
├── rap-battle-app          ← CAP Node.js app (CF app)
├── rap-battle-app-db       ← HANA HDI container
├── rap-battle-app-uaa      ← XSUAA service instance
└── rap-battle-app-dest     ← Destination service (optional)
```

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Data Model** | SAP CDS | Entity definitions, relationships |
| **Backend** | SAP CAP + Node.js | OData API, business logic |
| **Language** | TypeScript | Type-safe service handlers |
| **Database (dev)** | SQLite in-memory | Fast local development |
| **Database (prod)** | SAP HANA Cloud | Production persistence |
| **UI** | SAPUI5 Fiori Elements | Auto-generated from CDS annotations |
| **Auth** | SAP XSUAA | JWT-based role authentication |
| **Testing** | Jest + @cap-js/cds-test | Integration tests against real server |
| **CI/CD** | GitHub Actions | Automated test + MTA build |
| **Deployment** | SAP BTP Cloud Foundry | Cloud runtime |
| **Packaging** | MTA / mbt | Multi-target app build |

---

## License

Private learning project — not for production use.
