# FulboUY

Resultados y tablas de los principales torneos del fútbol uruguayo:
- Primera División
- Segunda División
- Primera Amateur

Built with Rails 8, SQLite, Hotwire and Tailwind. Code is in English; user-facing copy is in Spanish (`config/locales/es.yml`).

## Setup

```sh
bin/setup          # installs gems, prepares the DB and runs the seeds
bin/dev            # http://localhost:3000
bin/rails test
```

In development, the seeds generate **sample** matches with random results. See `NOTES.md` for the research on each tournament's format, the open questions and the candidate data sources.

## Domain

- `Competition` → `Season` → `Stage` (`round_robin` / `groups` / `knockout`) → `Group` → `Match`.
- `PointsAdjustment` holds sanctions.
- `HistoricalRecord` holds previous seasons' points for the relegation average.
- `ExternalId` and `TeamAlias` support future ingestion.
- Standings are computed, not stored:
  - `Standings::Table` handles per-stage tables and tiebreakers.
  - `Standings::Annual` builds the annual table.
  - `Standings::Relegation` builds the relegation table.
