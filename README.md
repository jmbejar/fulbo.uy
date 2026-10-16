# FulboUY

Resultados y tablas de los principales torneos del fútbol uruguayo:
- Primera División
- Segunda División
- Primera Amateur
- Copa AUF Uruguay

Built with Rails 8, SQLite, Hotwire and Tailwind. Code is in English; user-facing copy is in Spanish (`config/locales/es.yml`).

## Setup

```sh
bin/setup          # installs gems, prepares the DB and runs the seeds
bin/dev            # http://localhost:3000
bin/rails test
```

The seeds load the 2026 structure, without matches. To load real matches, run `bin/rails sync:all`. It takes a while, because Tenfield is slow. To work offline, use `SAMPLE_MATCHES=1 bin/rails db:seed` for random sample matches. Don't mix the two.

See `NOTES.md` for the research on each tournament's format, the open questions and the data sources.

## Match data

`SyncSourceJob` keeps matches up to date from three scraped sources (schedule in `config/recurring.yml`):

| Source | Role | Default run | `full` run |
|---|---|---|---|
| auf.org.uy | Builds the fixture: matches, rounds, dates and scores | hourly | — |
| Tenfield Estadísticas | Scores, published first; postponements | every 15 min, newest feed page only | daily, every page |
| es.wikipedia | Walkovers, missing results and points sanctions | hourly, only pages whose revision changed | any page |
| es.wikipedia (Copa AUF Uruguay) | The whole cup: fixture, results and teams | hourly, only if the revision changed | any revision |

- Each source files a `MatchReport` per match.
- `Sync::Resolver` merges the reports:
  - A Wikipedia walkover wins.
  - Otherwise the score comes from Tenfield, then Wikipedia, then AUF. Disagreements are logged.
  - A blank never clears a score.
- Wikipedia owns the `PointsAdjustment`s of every stage its tables map to.
- Mappings are `ExternalId` rows created by the seeds:
  - AUF page per competition, AUF tournament id per stage or group.
  - Tenfield season slug per stage or season.
  - Wikipedia page per stage or season.
  - Wikipedia page per cup season (source `wikipedia_cup`).
  - AUF club slug and crest per team, learned automatically.
- The cup is built from Wikipedia alone (`Sync::Wikipedia::CupImporter`):
  - It creates the cup's teams that we don't have yet (interior and Divisional D clubs).
  - Teams are identified by the Wikipedia article they link to, not by name.
- Team names are matched exactly (ignoring case and accents) against names and `TeamAlias`.
  - Unknown names are logged in the run summary. Add a `TeamAlias` for them.

```sh
bin/rails sync:auf
bin/rails sync:tenfield        # FULL=1 to walk every page
bin/rails sync:wikipedia       # FULL=1 to ignore unchanged revisions
bin/rails sync:wikipedia_cup   # FULL=1 to ignore an unchanged revision
bin/rails sync:all             # every source, fully
```

Each new season needs new mappings in the seeds (AUF tournament ids, Tenfield slugs, Wikipedia titles).

## Domain

- `Competition` → `Season` → `Stage` (`round_robin` / `groups` / `knockout`) → `Group` → `Match`.
- `PointsAdjustment` holds sanctions.
- `HistoricalRecord` holds previous seasons' points for the relegation average.
- `ExternalId` and `TeamAlias` map records to the sources; `MatchReport` holds what each source said about a match.
- Standings are computed, not stored:
  - `Standings::Table` handles per-stage tables and tiebreakers.
  - `Standings::Annual` builds the annual table.
  - `Standings::Relegation` builds the relegation table.
