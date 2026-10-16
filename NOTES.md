# FulboUY — Research notes and open questions

Snapshot of the 2026 season as researched on 2026-10-15 (sources mostly updated to 2026-10-11).
⚠ = unconfirmed; do not hardcode until verified.

## Primera División — Liga AUF Uruguaya 2026 ("Juan Carlos de Lima"), 16 teams
- Albion, Central Español and Deportivo Maldonado came up from Segunda.
- Plaza Colonia, Miramar Misiones and River Plate went down.
- **Apertura**: single round robin, 15 rounds. Champion: Racing.
- **Intermedio**: Series A/B, drawn from Apertura positions, then a final. Peñarol beat Wanderers 5–1.
  - The Intermedio final is not modelled yet (no knockout stage in the seeds).
- **Clausura**: single round robin, 7 Aug to about 15 Nov. Peñarol has a −1 point sanction.
- **Tabla Anual**: Apertura + Intermedio group stage + Clausura. The leader gets Copa Libertadores (group stage).
- **Championship**: two-leg semifinal between the Apertura and Clausura winners, then a two-leg final against the Anual leader.
  - ⚠ Not modelled. It is unclear whether winning both Apertura and Clausura cancels the playoff (Wikipedia) or only winning Apertura, Clausura and the Anual does (ESPN).
- **Descenso**: points per match over 2025 + 2026; the bottom 3 go down.
  - ⚠ How averages are computed for promoted teams is unconfirmed. We currently use only their Primera matches.
- **Tiebreakers**: goal difference → goals for → head-to-head → lots. A tie for 1st is decided by a playoff match, which is not modelled.
- Sources:
  - https://en.wikipedia.org/wiki/2026_Liga_AUF_Uruguaya
  - https://rsssf.org/tablesu/uru2026.html

## Segunda División Profesional 2026 ("Elías Zumar"), 14 teams
- **Torneo Competencia**: 2 groups of 7, then a final (Fénix 1–0 Oriental).
- **Regular stage**: double round robin, 8 May to 8 Nov.
- **Annual table** = Competencia + regular stage.
- **Promotion**: the top 2 go up directly. The 3rd spot goes to the Reclasificatorio among 3rd–6th; the Competencia champion takes 6th if it finishes lower.
- ⚠ **Relegation**: no direct relegation in 2026; instead a playoff against Divisional C teams. Sources disagree on which amateur teams play it.
- ⚠ Wikipedia says the regular stage has 26 rounds but shows 28 matches played.
- Source: https://en.wikipedia.org/wiki/2026_Uruguayan_Segunda_Divisi%C3%B3n_season

## Primera División Amateur (Divisional C) 2026, 29 teams
- **Torneo Inicial**: Series A, B and C, then a playoff.
  - ⚠ Playoff format unclear: top 3 per series plus the best runner-up?
- **Torneo Final**: the top 6 of each series (18 teams), single round robin.
- **Promotion**: the Final champion goes up. Inicial champion vs Final runner-up plays for a second spot.
- ⚠ The name "Deportivo LSM" comes from press reports and was not verified.
- Source: https://www.montevideo.com.uy/Deportes/Desde-Rampla-hasta-el-equipo-de-Suarez-y-Messi-quedo-fijada-la-primera-fecha-de-la-C-uc960455

## Data sources (ingestion is deferred)
The model is ready for it: `ExternalId` maps records to source IDs and `TeamAlias` normalises team names across sources.

| Source | Coverage | Notes |
|---|---|---|
| auf.org.uy | All divisions | HTML only, scraping required. Not yet verified that it can be scraped. |
| API-Football | Primera, likely Segunda | Needs an API key (free tier: 100 requests/day). Each stage is a separate "league". ⚠ League IDs unconfirmed; check `GET /leagues?country=Uruguay`. |
| TheSportsDB | Primera (league 4432) | Data looked stale. |
| Footystats | Includes Primera Amateur | Only aggregator found that covers the amateur league. |
| FotMob / Sofascore | Primera | Unofficial APIs. |

Always compute the Anual and relegation tables ourselves.

## Sample data
- In development, `db/seeds.rb` generates fixtures with **random results**. They are not real results.
- `db/data/historical_2025.csv` holds **sample** 2025 points that still need to be verified.
- The seeds use a frozen "today" (`SAMPLE_TODAY = 2026-10-15`) to decide which sample matches are already played.

## Known limitations
- Fragment caches are keyed on `Stage#updated_at`, which `Match` and `PointsAdjustment` touch. `GroupMembership` changes do not bust the cache yet; handle this when ingestion writes memberships.
- `Stage#teams` for a round-robin stage comes from its fixture once it has matches, and from the season's teams before that. This is how the amateur Torneo Final lists only its 18 teams.
- Turbo Frame tab navigation updates the URL but not the page `<title>`.
- `json` is pinned to `~> 2.21` because json 3.x breaks ActiveSupport 8.0 (`unknown keyword: quirks_mode`).
