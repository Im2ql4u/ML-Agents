---
description: "Start every session. Reads logs and repo state, reports honestly, asks what we are working on."
agent: agent
---

# Session Open

> **How to use:** `@session-open.md` at the start of every session. No input needed.

---

Orient yourself completely before touching anything. No code, no suggestions, no changes until you have completed all steps and I have confirmed we are ready.

---

## Step 1 — Read the logs

Read these files in full if they exist. Note any that are missing.

- `SESSION_LOG.md` — full file
- `DECISIONS.md` — full file
- `JOURNAL.md` — full file
- `ARCHIVE.md` — last 3 entries only

---

## Step 2 — Read the repo

Directory listing excluding `data/`, `outputs/`, `results/`, `.git/`. Then read:

- `README.md`
- Top-level config files
- `src/` and `core/` structure
- Most recent results folder in `results/` — summary files only, not raw data

---

## Step 3 — Synthesize honestly

Report on:

**Project** — one sentence: what this is and what it is genuinely trying to achieve

**Foundation status** — go through the diagnostic hierarchy explicitly:
- Is the data pipeline known to be correct, or assumed?
- Are splits verified to respect data correlation structure?
- Is there a verified baseline result?
- Are there any known implementation uncertainties?
State what is verified and what is assumed. Do not conflate them.

**Recent history** — what happened last session, what was concluded, what was left open

**Active decisions** — choices currently in effect that constrain what we do next

**Honest assessment** — does the current direction make sense? Are there things in the logs that look suspicious, inconsistent, or worth questioning before we proceed? Say so if there are. Do not just report what looks good.

**Open questions** — unresolved things that need a decision before proceeding

---

## Step 4 — Ask two things

1. *Is there anything in what I just read that you want to discuss before we start?*
2. *What are we working on today?*

Wait for both answers. Do not proceed until I respond.
