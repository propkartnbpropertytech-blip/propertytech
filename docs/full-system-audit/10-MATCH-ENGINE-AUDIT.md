# 10 — Match Engine Audit

## Server

`MatchingService.evaluateProperty` scores listing, location, configuration, budget, and property type, capped at 100. Threshold comes from `match_criteria`, default 60, clamped from 10 to 100. Route: `GET/POST /api/v1/requirements/:id/matches`.

## Client

`PropertyRequirementMatcher` uses different budget bands from the server (about ±20 / ±35 on the client and ±15 / ±25 on the server). The client threshold is stored in SharedPreferences under `propkart_run_match_criteria_threshold` and also read from `GET /config/match-criteria`.

## Consequence

The same property and requirement can be inside the threshold on one side and outside it on the other. PostgreSQL is authoritative only when the UI uses the server result. A local score is not the canonical match.

## Not executed

0 percent, partial, exact threshold, 100 percent, missing fields, duplicate rows, large set, and a permission change of the threshold. Status: `NOT TESTABLE`.
