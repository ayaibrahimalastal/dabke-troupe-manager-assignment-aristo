# 🎭 Al-Quds Dabke Troupe Manager

A command-line application built with **Dart** to manage a Palestinian Dabke troupe — members, performances, assignments, and reports.  
Developed as the **Week 1 assignment** for the Flutter Mentorship program, demonstrating core **OOP** and **SOLID** principles.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [OOP & SOLID Principles Applied](#oop--solid-principles-applied)
- [Class Hierarchy](#class-hierarchy)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Example Session](#example-session)

---

## Overview

**Al-Quds Dabke Troupe Manager** is an interactive CLI tool that allows troupe administrators to:

- Register core members and guest performers
- Schedule performances of different types
- Assign members to performances
- Enforce type-specific business rules (e.g. youth mentor required for festivals)
- Generate summary reports of upcoming performances and member activity

---

## Features

| Feature | Description |
|---|---|
| ➕ Add Core Member | Register a permanent member with a fixed role |
| 👤 Add Guest Performer | Register a guest with a flexible, per-performance role |
| 🎪 Create Performance | Schedule a Standard, Formal Ceremony, or Youth Festival performance |
| 🔗 Assign Member | Link a member to a specific performance |
| ✅ Mark Completed | Close a performance (with validation checks) |
| 📊 View Reports | Upcoming performances · Most active members · Unassigned performances |

---

## Project Structure

```
DabkeTroupeManager/
└── DabkeTroupeManager.dart   # Single-file Dart application
```

### Core Classes

```
Abstractions
├── TroupeMember          (abstract)
├── Performance           (abstract)
├── NotificationService   (abstract)
├── ReportGenerator       (abstract)
├── BasicController       (abstract)
└── NetworkController     (abstract)

Concrete Members
├── CoreMember            extends TroupeMember
└── GuestPerformer        extends TroupeMember

Concrete Performances
├── StandardPerformance         extends Performance
├── FormalCeremonyPerformance   extends Performance
└── YouthFestivalPerformance    extends Performance

Services
├── ConsoleNotificationService  implements NotificationService
├── VolunteerNotifier           (depends on NotificationService abstraction)
├── ConsoleReportGenerator      implements ReportGenerator
└── TroupeManager               (orchestrator)
```

---

## OOP & SOLID Principles Applied

### Single Responsibility Principle (SRP)
Each class has exactly one job. `TroupeManager` orchestrates operations, `ConsoleReportGenerator` handles all output, and `VolunteerNotifier` handles notifications — none of them overlap.

### Open/Closed Principle (OCP)
The `Performance` hierarchy uses a `validate()` hook as the extension point. Adding a new performance type (e.g. `InternationalTourPerformance`) means adding a new subclass — zero changes to existing code.

### Liskov Substitution Principle (LSP)
Every `Performance` and `TroupeMember` subclass fully honours its base class contract — no unexpected exceptions, no broken behaviour when a subtype is substituted.

### Interface Segregation Principle (ISP)
Controllers are split into `BasicController` (initState / dispose) and `NetworkController` (handleNetworkSync). A simple controller only implements what it actually needs.

### Dependency Inversion Principle (DIP)
`VolunteerNotifier` depends on the abstract `NotificationService`, injected via constructor — not on `ConsoleNotificationService` directly. Swapping notification channels requires zero changes to `VolunteerNotifier`.

---

## Class Hierarchy

```
TroupeMember (abstract)
├── CoreMember         — fixed role, encapsulated and immutable after construction
└── GuestPerformer     — mutable currentRole, can vary per performance

Performance (abstract)
├── StandardPerformance        — no special validation rules
├── FormalCeremonyPerformance  — requires at least one member assigned
└── YouthFestivalPerformance   — requires at least one youth mentor
```

> **Design decision:** `CoreMember` and `GuestPerformer` are separate subclasses rather than a single `Member` with an `isGuest` flag. This lets the compiler enforce the difference — no scattered `if/else` checks throughout the codebase.

---

## Getting Started

### Prerequisites

- [Dart SDK](https://dart.dev/get-dart) `>=3.0.0`

Verify your installation:

```bash
dart --version
```

### Run

```bash
dart run DabkeTroupeManager.dart
```

---

## Usage

The app presents an interactive menu:

```
🎭 Al-Quds Dabke Troupe Manager
================================

Choose an action:
  1. Add Core Member
  2. Add Guest Performer
  3. Create Performance
  4. Assign Member to Performance
  5. Mark Performance as Completed
  6. View Reports
  0. Exit
>
```

Type the number and press **Enter** to proceed. Each option prompts for the required fields.

---

## Example Session

```
> 1
Name: Ahmad
City of origin: Jerusalem
Fixed role (lead dancer / musician / singer / drummer): lead dancer
Member added: Ahmad (Core – lead dancer) – from Jerusalem

> 3
Performance title: Independence Ceremony
City: Ramallah
Date (e.g. 2025-09-15): 2025-11-15
Type: 1=Standard  2=Formal Ceremony  3=Youth Festival
> 2
Performance created: Independence Ceremony
[NOTIFICATION] New performance scheduled: Independence Ceremony on 2025-11-15

> 4
Member name: Ahmad
Performance title: Independence Ceremony
Ahmad assigned to "Independence Ceremony".

> 6

===== Upcoming Performances =====
  • Independence Ceremony | Ramallah | 2025-11-15
    - Ahmad (Core – lead dancer) – from Jerusalem

===== Most Active Core Members =====
  • Ahmad – 1 performance(s)

===== Performances With No Members Assigned =====
  All performances have at least one member.
```

---

## Assignment Context

| Item | Details |
|---|---|
| Program | Flutter Mentorship |
| Week | Week 1 |
| Topics | OOP Fundamentals · SOLID Principles |
| Language | Dart 3+ |
| Deliverable | Console application + written SOLID explanation |
