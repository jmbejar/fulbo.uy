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
- Regular stage: 26 rounds, 182 matches (verified on auf.org.uy, 2026-10-15).
- Source: https://en.wikipedia.org/wiki/2026_Uruguayan_Segunda_Divisi%C3%B3n_season

## Primera División Amateur (Divisional C) 2026, 29 teams
- **Torneo Inicial**: Series A, B and C, then a playoff.
  - Playoff: 2 semifinals and a final, so 4 teams (verified on auf.org.uy). ⚠ Qualification rule still unconfirmed (likely the 3 series winners plus the best runner-up).
- **Torneo Final**: the top 6 of each series (18 teams), single round robin.
- **Promotion**: the Final champion goes up. Inicial champion vs Final runner-up plays for a second spot.
- ⚠ The name "Deportivo LSM" comes from press reports and was not verified.
- Source: https://www.montevideo.com.uy/Deportes/Desde-Rampla-hasta-el-equipo-de-Suarez-y-Messi-quedo-fijada-la-primera-fecha-de-la-C-uc960455

## Copa AUF Uruguay 2026 (5th edition), 40 teams
- Researched on 2026-10-16 from https://es.wikipedia.org/wiki/Copa_AUF_Uruguay_2026, which is the only source the app uses for the cup.
- The champion gets Copa Libertadores 2027 (Uruguay 4).
- Entrants: the 16 Primera teams, 8 from Segunda, 4 from Primera C, 2 from Divisional D and 10 interior (OFI) clubs.
- **Professional route**: 6 groups of 4, single round robin. The top 2 and the 4 best thirds go through.
  - ⚠ The tiebreakers and how the best thirds are compared are not modelled. The thirds table is not shown.
- **Amateur route**: a one-match knockout among 8 Primera C teams (4 go through).
- **Second stage**: 16 professional and 16 amateur teams, one match each, penalties if tied.
- **Final phase**: round of 16, quarterfinals, semifinals and final, one match each. Semifinals and final are played on neutral ground.
- Modelled as two stages: "Fase de grupos" and "Eliminatorias", a knockout stage whose rounds are named in `Stage#round_names`.
- Wikipedia quirks:
  - Every match is a `{{Partidos}}` template. Its phase comes from the headings above it, and the importer maps them in `KNOCKOUT_ROUNDS`. A renamed heading leaves its matches unmatched (logged).
  - Group matches carry no round number. The round is worked out from the pairings: in a group of 4 each round is one of the three ways to pair the teams. Rounds are ordered by first kickoff, so they can differ from AUF's numbering when a round was postponed (Grupo 3).
  - A link label can drop the club's disambiguation ("[[Club Atlético Atenas (San Carlos)|Atenas]]"), so teams are keyed on the article title.
  - On 2026-10-16 Wikipedia had Boston River 0–0 River Plate with penalties 4–3; AUF had 5–2. Its round of 16 list also named River Plate, who lost.

## Data sources
In use: AUF, Tenfield Estadísticas and Wikipedia (see README, "Match data"). The rows below are the alternatives that were considered.

| Source | Coverage | Notes |
|---|---|---|
| auf.org.uy | All divisions | **In use**: fixture. See "AUF scraping" below. |
| Tenfield Estadísticas | Primera, Segunda | **In use**: fastest scores. See "Tenfield" below. |
| es.wikipedia | All divisions | **In use**: corrections. See "Wikipedia" below. |
| API-Football | Primera, likely Segunda | Rejected: the free plan doesn't cover the current season. |
| TheSportsDB | Primera (league 4432) | Data looked stale. |
| Footystats | Includes Primera Amateur | Only aggregator found that covers the amateur league. |
| FotMob / Sofascore | Primera | Unofficial APIs. |

Always compute the Anual and relegation tables ourselves.

## Sample data
- With `SAMPLE_MATCHES=1`, `db/seeds.rb` generates fixtures with **random results**. They are not real results, and they would collide with synced matches.
- `db/data/historical_2025.csv` holds **sample** 2025 points that still need to be verified.
- The seeds use a frozen "today" (`SAMPLE_TODAY = 2026-10-15`) to decide which sample matches are already played.

## Known limitations
- Fragment caches are keyed on `Stage#updated_at`, which `Match` and `PointsAdjustment` touch. The AUF importer touches the stage when it adds a `GroupMembership`.
- `Stage#teams` for a round-robin stage comes from its fixture once it has matches, and from the season's teams before that. This is how the amateur Torneo Final lists only its 18 teams.
- Turbo Frame tab navigation updates the URL but not the page `<title>`.
- Sync gaps:
  - The AUF importer never deletes matches that disappear from the fixture, such as after a withdrawal. They would stay listed as scheduled.
  - The cup importer doesn't either: a match removed from the Wikipedia page stays.
  - An AUF date without a time is stored at 00:00.
  - The Intermedio has no Tenfield season slug.
  - Segunda's regular stage gets no Wikipedia sanctions, because its table is hand-written.
  - The daily full Tenfield run walks every feed page but skips scores it already has, except from the last 7 days. A correction Tenfield makes to an older score is missed.
  - League knockout rounds (Intermedio final, playoffs) are not imported, because they aren't modelled. Only the cup has a knockout stage.
- `json` is pinned to `~> 2.21` because json 3.x breaks ActiveSupport 8.0 (`unknown keyword: quirks_mode`).

## AUF scraping (spike 2026-10-15)
One server-rendered page per division holds every fixture of the season. Results are inline (no AJAX), and robots.txt allows everything.
- Primera: `https://www.auf.org.uy/liga-auf-uruguaya/`. `/primera-division/` is a stale 2019 page.
- Segunda: `https://www.auf.org.uy/segunda-division-profesional/`
- Amateur: `https://www.auf.org.uy/primera-divisional-c/`
- Pages are ISO-8859-1.
- Each tournament is a pane `div#fmuestro_cNNNN`, titled by `#tab_cNNNN`. Round titles are `div[id^=fixnom_]` ("FECHA n"). Matches are `.item-fixture`, each with:
  - home and away `<a href="/club-slug/">`
  - `.resultado`: "2 - 1", "(4) 1 - 1 (3)" with penalties, or blank
  - `.fecha_estadio`: "dd/mm/yyyy - HH:MM h" or "dd-mm-yyyy", plus the venue. Blank when not yet scheduled.
- Tournament IDs change every season. In 2026:
  - Primera: Apertura c1445, Intermedio A/B c1513/c1514, Intermedio final c1528, Clausura c1529.
  - Segunda: Competencia A/B c1453/c1454, final c1482, regular c1500.
  - Amateur: Inicial A/B/C c1479/c1480/c1478, semis c1519, final c1520, Torneo Final c1527.
  - The Primera page also has Copa de la Liga (c1423) and Supercopa (c1443), which are excluded.
  - The Copa AUF Uruguay has its own page (`/copaaufuruguay/`, c1531–c1558 in 2026). It's not mapped, because the cup comes from Wikipedia.
- Match counts match the stage formats in the seeds. Apertura and Clausura tables computed from AUF match RSSSF exactly (Clausura before Peñarol's −1).
- Caveats:
  - There is no status markup. A blank score after kickoff could mean postponed or suspended, and a live match probably shows a partial score.
  - Display names differ from ours ("D. Maldonado", "M.C. Torque", "FRONTERA RIVERA RENEGADES", "Basañez"). Match teams on the club slug instead.
- Cross-check sources:
  - ESPN JSON (`site.api.espn.com/.../soccer/uru.1/scoreboard?dates=YYYYMMDD`): Primera only, one day per request.
  - RSSSF `uru2026.html`: plain text.
- Do not scrape AUF's standings tables. They come from COMET (AUF's match-management system), update daily and are partial: on 2026-10-15 the Torneo Final table showed Bella Vista with 27 pts from 11 matches. A table computed from the fixture gives 30 from 12, which matches Montevideo Portal and Wikipedia in all 18 rows.
- AUF office decisions are not reflected in fixture scores, so they need manual corrections. In Primera C 2026:
  - Bella Vista lost the Inicial win over Los Halcones, and Los Halcones got the points.
  - Cooper withdrew (unpaid debts), so its rivals get the points.
  - Rocha, Parque del Plata and Los Gorriones withdrew from the Torneo Final, replaced by Los Halcones, Durazno and Salto.
  - Some matches were postponed. @elascensouy on X and the press are the best signals for these.
- Follow-up: the `tdescenso` (DESCENSO) tab may hold the real 2025 points for the relegation average.

## Wikipedia as a corrections source (spike 2026-10-15)
Goal: no admin UI. es.wikipedia editors already record AUF office decisions.
- Fetch via the MediaWiki API (`action=parse&prop=text|wikitext|revid`) with a descriptive User-Agent. Content is CC BY-SA, so attribution is needed.
- Pages:
  - "Campeonato Uruguayo de Primera Divisional C 2026"
  - "Campeonato Uruguayo de Segunda División 2026"
  - "Torneo Clausura 2026 (Uruguay)"
  - Primera is split into one page per tournament. The Clausura page has a Football table, including `ajustar_puntos_PEÑ=-1`. Team codes can be non-ASCII, so `\w` regexes miss them.
  - Segunda: only the Competencia A/B tables use the module. The regular-stage table is hand-written and looked stale (28 played per team on 2026-10-15), so Segunda gets no structured corrections.
- Standings use `{{#invoke:Football table}}`, which is structured:
  - `ganados_X / empates_X / perdidos_X / gf_X / gc_X`
  - `ajustar_puntos_X=-3` with the reason in `hth_X`. This maps directly to `PointsAdjustment`.
  - In "Tabla general", `ajustar_puntos` is the Serie C weighting, not a sanction.
- Results are one HTML table per round (Local / Resultado / Visitante / Estadio / Fecha / Hora):
  - Date and time cells use rowspan.
  - Walkovers are shown as `w/o`, with the winner in bold.
  - "Libre: X" rows are byes.
  - Unplayed matches show "vs.". Unscheduled teams can be blank (Clausura rounds 12–15).
  - Dates are "27 de junio" with no year.
- Checks:
  - Every Football table recomputes exactly from the page's own results plus `ajustar_puntos`.
  - Primera C vs AUF: 266/279 identical. The rest are AUF errors: 8 Cooper walkovers recorded as 0-0, and Serie A round 9 not entered.
  - Clausura vs AUF: 88/88 identical.
  - Segunda vs AUF: 189/196 identical. The rest are Wikipedia lag: round 22, played 10–11 Oct, was still "vs." on 15 Oct.
  - No case where both sources had different real scores.
- Team names differ per source, and fuzzy matching collides ("Cerro" vs "Cerro Largo"). Use an explicit alias table per source.

## Tenfield Estadísticas (spike 2026-10-15)
- `estadisticas.tenfield.com.uy` runs WordPress + SportsPress.
  - The REST API needs authentication; don't try to get around it.
  - robots.txt only disallows `/wp-admin/`.
- Season slugs:
  - Primera: `apertura-2026`, `clausura-2026` (the Intermedio slug wasn't found).
  - Segunda: `lapro-anual-2026`, covering Competencia and the regular stage.
- Each match is a post titled "Home — Away", published at kickoff time.
  - `/season/<slug>/feed/?paged=N` lists them newest first, 10 per page.
  - Past the last page, the feed drifts into older site-wide posts.
  - Unplayed matches don't appear.
- Match pages:
  - The header block `.sp-template-event-logos` holds the score, or "Pospuesto".
  - A postponed match gets a new post when it is replayed.
- Its matchday numbers don't follow AUF's, so matches are found by teams and date.
- Pages are slow (about 6 s each), so the daily full run takes a while.
- Clausura check: 79/80 results equal AUF's. The other one was the postponed post.
- Its standings apply sanctions (Peñarol −1), and on 2026-10-15 its Segunda table already included round 22, which Wikipedia still lacked.
