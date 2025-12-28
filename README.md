# synapse_runner (ADHD Accountability App)

A mobile-first intervention tool that interrupts you **before** you fuck up, not after.

## The Problem

ADHD makes everything harder: appointments vanish from memory, impulses win over logic, hyperfocus destroys relationships, meds get forgotten, and you lose track of what you were doing mid-task.

Generic productivity apps don't help. They assume a neurotypical brain. This app doesn't.

## Core Philosophy

**"Interrupt me BEFORE I fuck up"**

Not "track what I did" (too late). Not "help me plan" (planning paralysis). But: stop me NOW when I'm about to make a mistake. Remind me NOW when I'm forgetting something.

## Features (v0.1 MVP)

| Feature | Problem | Solution |
|---------|---------|----------|
| **Appointment Killer** | Forget appointments | Persistent notifications that can't be dismissed. 24h → 1h → 15min reminders. |
| **Impulse Brake** | Impulsive decisions | 24-48h cooling-off period before any logged decision unlocks. |
| **Hyperfocus Timer** | Lose track of time, neglect family | Intrusive alarm + screen takeover when time limit hit. Wife-time blocking. |
| **Medication Tracker** | Forget meds or double-dose | Morning alarm with photo confirmation. History tracking. |
| **Current Task Banner** | Working memory failure | Persistent notification showing what you're doing. Survives context switches. |

## What This Is NOT

- ❌ Generic productivity app (Todoist, Notion)
- ❌ Gamified habit tracker (no points, streaks, or badges)
- ❌ AI-powered assistant
- ❌ Social platform or community
- ❌ Replacement for medication or therapy
- ❌ Polished commercial product

This is a personal tool built to solve specific problems. Rough edges are fine. Function over form.

## Tech Stack

- **Flutter** (Android first)
- **Local storage** (Hive/sqflite - no backend)
- **Persistent notifications** (flutter_local_notifications, android_alarm_manager)

## Status

Personal project. Private repo. Built for one user first, shared later if it works.

## License

MIT
