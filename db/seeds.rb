# Loads the 2026 structure of the Uruguayan tournaments (competitions,
# stages, groups, teams and known points adjustments) and maps them to the
# external sources the sync jobs read (see app/models/sync.rb).
#
# With SAMPLE_MATCHES=1 it also generates SAMPLE matches with random results,
# for working offline. Don't combine them with the sync jobs: the synced
# fixture would be added on top of them.
#
# Sources for the structure: see NOTES.md.

require "csv"

SEASON_YEAR = 2026
SAMPLE_TODAY = Date.new(2026, 10, 15)

PRIMERA_TEAMS = [
  [ "Albion", "Albion", "Montevideo" ],
  [ "Boston River", "Boston River", "Montevideo" ],
  [ "Central Español", "Central Español", "Montevideo" ],
  [ "Cerro", "Cerro", "Montevideo" ],
  [ "Cerro Largo", "Cerro Largo", "Melo" ],
  [ "Danubio", "Danubio", "Montevideo" ],
  [ "Defensor Sporting", "Defensor", "Montevideo", [ "Defensor", "Def. Sporting" ] ],
  [ "Deportivo Maldonado", "Dep. Maldonado", "Maldonado", [ "D. Maldonado" ] ],
  [ "Juventud", "Juventud", "Las Piedras", [ "Juventud de Las Piedras" ] ],
  [ "Liverpool", "Liverpool", "Montevideo" ],
  [ "Montevideo City Torque", "City Torque", "Montevideo", [ "Torque", "MCT", "M.C. Torque" ] ],
  [ "Montevideo Wanderers", "Wanderers", "Montevideo", [ "Wanderers" ] ],
  [ "Nacional", "Nacional", "Montevideo", [ "Club Nacional de Football" ] ],
  [ "Peñarol", "Peñarol", "Montevideo", [ "CA Peñarol", "Penarol" ] ],
  [ "Progreso", "Progreso", "Montevideo" ],
  [ "Racing", "Racing", "Montevideo", [ "Racing Club de Montevideo" ] ]
].freeze

SEGUNDA_TEAMS = [
  [ "Atenas", "Atenas", "San Carlos", [ "Atenas de San Carlos" ] ],
  [ "Cerrito", "Cerrito", "Montevideo" ],
  [ "Colón", "Colón", "Montevideo", [ "Colón FC" ] ],
  [ "Fénix", "Fénix", "Montevideo" ],
  [ "Huracán", "Huracán", "Montevideo", [ "Huracán FC" ] ],
  [ "La Luz", "La Luz", "Montevideo" ],
  [ "Miramar Misiones", "Miramar", "Montevideo" ],
  [ "Oriental", "Oriental", "La Paz", [ "Oriental de La Paz" ] ],
  [ "Paysandú", "Paysandú", "Paysandú", [ "Paysandú FC" ] ],
  [ "Plaza Colonia", "Plaza Colonia", "Colonia del Sacramento" ],
  [ "Rentistas", "Rentistas", "Montevideo" ],
  [ "River Plate", "River Plate", "Montevideo", [ "River Plate Montevideo" ] ],
  [ "Tacuarembó", "Tacuarembó", "Tacuarembó", [ "Tacuarembó FC" ] ],
  [ "Uruguay Montevideo", "Uruguay Mvdeo.", "Montevideo" ]
].freeze

# Spellings used by the sources, when they differ from ours.
AMATEUR_ALIASES = {
  "Frontera Rivera" => [ "Frontera Rivera Renegades" ],
  "Salto" => [ "Salto FC" ],
  "Bella Italia" => [ "Sportivo Bella Italia" ]
}.freeze

AMATEUR_SERIES = {
  "Serie A" => [ "Frontera Rivera", "Rocha", "Deutscher", "Bella Vista", "Alto Perú", "Mar de Fondo",
                 "Deportivo Italiano", "Los Halcones", "Cooper", "Rampla Juniors" ],
  "Serie B" => [ "Artigas", "Durazno", "Potencia", "Parque del Plata", "Deportivo LSM", "Platense",
                 "Lito", "Salus", "Canadian", "Basáñez" ],
  "Serie C" => [ "Salto", "Deportivo Colonia", "Bella Italia", "Terremoto", "Villa Teresa", "Sud América",
                 "Villa Española", "Huracán Buceo", "Los Gorriones" ]
}.freeze

# Circle-method round robin. Returns an array of rounds, each an array of
# [home, away] pairs. Odd team counts get a bye each round.
def round_robin(teams, double: false)
  list = teams.dup
  list << nil if list.size.odd?
  rounds = (list.size - 1).times.map do |r|
    pairs = (list.size / 2).times.map do |i|
      pair = [ list[i], list[-1 - i] ]
      (r + i).even? ? pair : pair.reverse
    end
    list = [ list.first, list.last, *list[1..-2] ]
    pairs.reject { |pair| pair.include?(nil) }
  end
  double ? rounds + rounds.map { |round| round.map(&:reverse) } : rounds
end

def upsert_team(name, short_name, city, aliases = [])
  team = Team.find_or_create_by!(slug: name.parameterize) do |t|
    t.name = name
    t.short_name = short_name
    t.city = city
  end
  aliases.each { |alias_name| team.team_aliases.find_or_create_by!(name: alias_name) }
  team
end

def schedule!(stage, rounds, starts_on:, group: nil, rng:, round_offset: 0)
  rounds.each_with_index do |pairs, index|
    date = starts_on + (index * 7).days
    pairs.each do |home, away|
      match = stage.matches.find_or_initialize_by(home_team: home, away_team: away, round: index + 1 + round_offset)
      match.group = group
      match.kicks_off_at = Time.zone.local(date.year, date.month, date.day, [ 15, 17, 19 ].sample(random: rng), 0)
      if date < SAMPLE_TODAY
        match.assign_attributes(status: :finished, home_goals: goals(rng), away_goals: goals(rng))
      else
        match.assign_attributes(status: :scheduled, home_goals: nil, away_goals: nil)
      end
      match.save!
    end
  end
end

def goals(rng) = [ 0, 0, 1, 1, 1, 2, 2, 3, 4 ].sample(random: rng)

def zone(from, to, key) = { "from" => from, "to" => to, "zone" => key }

# Maps a record to its id in an external source (see Sync).
def link!(record, source, external_id)
  ExternalId.find_or_create_by!(source: source, external_id: external_id, identifiable_type: record.class.name) do |link|
    link.identifiable = record
  end
end

sample_matches = ENV["SAMPLE_MATCHES"].present?
rng = Random.new(SEASON_YEAR)

ActiveRecord::Base.transaction do
  # --- Primera División ------------------------------------------------------
  primera = Competition.find_or_create_by!(slug: "primera") { |c| c.name = "Primera División"; c.tier = 1 }
  season = primera.seasons.find_or_initialize_by(year: SEASON_YEAR)
  season.update!(
    official_name: "Torneo Uruguayo Juan Carlos de Lima",
    current: true,
    relegation_years: 2,
    annual_zones: [ zone(1, 1, "libertadores") ],
    relegation_zones: [ zone(14, 16, "relegation") ]
  )
  teams = PRIMERA_TEAMS.map { |args| upsert_team(*args) }
  teams.each { |team| season.participations.find_or_create_by!(team: team) }

  apertura = season.stages.find_or_initialize_by(slug: "apertura")
  apertura.update!(name: "Apertura", position: 1, format: :round_robin, counts_for_annual: true,
                   zones: [ zone(1, 1, "champion") ])
  intermedio = season.stages.find_or_initialize_by(slug: "intermedio")
  intermedio.update!(name: "Intermedio", position: 2, format: :groups, counts_for_annual: true,
                     zones: [ zone(1, 1, "final") ])
  clausura = season.stages.find_or_initialize_by(slug: "clausura")
  clausura.update!(name: "Clausura", position: 3, format: :round_robin, counts_for_annual: true, current: true,
                   zones: [ zone(1, 1, "champion") ])

  serie_a = intermedio.groups.find_or_create_by!(name: "Serie A") { |g| g.position = 1 }
  serie_b = intermedio.groups.find_or_create_by!(name: "Serie B") { |g| g.position = 2 }

  link!(primera, "auf", "liga-auf-uruguaya")
  link!(apertura, "auf", "c1445")
  link!(serie_a, "auf", "c1513")
  link!(serie_b, "auf", "c1514")
  link!(clausura, "auf", "c1529")
  link!(apertura, "tenfield", "apertura-2026")
  link!(clausura, "tenfield", "clausura-2026")
  link!(apertura, "wikipedia", "Torneo Apertura 2026 (Uruguay)")
  link!(clausura, "wikipedia", "Torneo Clausura 2026 (Uruguay)")

  # Once synced, Wikipedia owns the Clausura sanctions; this keeps the known
  # one available offline.
  penarol = Team.find_by!(slug: "penarol")
  clausura.points_adjustments.find_or_create_by!(team: penarol) do |adjustment|
    adjustment.points = -1
    adjustment.reason = "Sanción"
  end

  if sample_matches
    schedule!(apertura, round_robin(teams.shuffle(random: rng)), starts_on: Date.new(2026, 2, 1), rng: rng)
    # Intermedio series are drawn from the Apertura table (odd/even positions).
    apertura_order = Standings::Table.for_stage(apertura).map(&:team)
    [ serie_a, serie_b ].each_with_index do |group, i|
      group_teams = apertura_order.select.with_index { |_, pos| pos % 2 == i }
      group_teams.each { |team| group.group_memberships.find_or_create_by!(team: team) }
      schedule!(intermedio, round_robin(group_teams), starts_on: Date.new(2026, 5, 9), group: group, rng: rng)
    end
    schedule!(clausura, round_robin(teams.shuffle(random: rng)), starts_on: Date.new(2026, 8, 8), rng: rng)
  end

  # --- Segunda División -------------------------------------------------------
  segunda = Competition.find_or_create_by!(slug: "segunda") { |c| c.name = "Segunda División"; c.tier = 2 }
  season = segunda.seasons.find_or_initialize_by(year: SEASON_YEAR)
  season.update!(
    official_name: "Torneo Elías Zumar",
    current: true,
    annual_zones: [ zone(1, 2, "promotion"), zone(3, 6, "promotion_playoff"), zone(13, 14, "relegation_playoff") ]
  )
  teams = SEGUNDA_TEAMS.map { |args| upsert_team(*args) }
  teams.each { |team| season.participations.find_or_create_by!(team: team) }

  competencia = season.stages.find_or_initialize_by(slug: "competencia")
  competencia.update!(name: "Torneo Competencia", position: 1, format: :groups, counts_for_annual: true,
                      zones: [ zone(1, 1, "final") ])
  regular = season.stages.find_or_initialize_by(slug: "regular")
  regular.update!(name: "Fase regular", position: 2, format: :round_robin, counts_for_annual: true, current: true)
  competencia_groups = [ "Serie A", "Serie B" ].each_with_index.map do |name, i|
    competencia.groups.find_or_create_by!(name: name) { |g| g.position = i + 1 }
  end

  link!(segunda, "auf", "segunda-division-profesional")
  link!(competencia_groups[0], "auf", "c1453")
  link!(competencia_groups[1], "auf", "c1454")
  link!(regular, "auf", "c1500")
  link!(season, "tenfield", "lapro-anual-2026")
  link!(season, "wikipedia", "Campeonato Uruguayo de Segunda División 2026")

  if sample_matches
    shuffled = teams.shuffle(random: rng)
    [ shuffled.first(7), shuffled.last(7) ].zip(competencia_groups).each do |group_teams, group|
      group_teams.each { |team| group.group_memberships.find_or_create_by!(team: team) }
      schedule!(competencia, round_robin(group_teams), starts_on: Date.new(2026, 3, 14), group: group, rng: rng)
    end
    schedule!(regular, round_robin(teams.shuffle(random: rng), double: true), starts_on: Date.new(2026, 5, 9), rng: rng)
  end

  # --- Primera División Amateur ----------------------------------------------
  amateur = Competition.find_or_create_by!(slug: "amateur") { |c| c.name = "Primera Amateur"; c.tier = 3 }
  season = amateur.seasons.find_or_initialize_by(year: SEASON_YEAR)
  season.update!(official_name: "Divisional C", current: true)

  inicial = season.stages.find_or_initialize_by(slug: "inicial")
  inicial.update!(name: "Torneo Inicial", position: 1, format: :groups, zones: [ zone(1, 3, "playoff") ])
  final = season.stages.find_or_initialize_by(slug: "final")
  final.update!(name: "Torneo Final", position: 2, format: :round_robin, current: true,
                zones: [ zone(1, 1, "promotion"), zone(2, 2, "promotion_playoff") ])

  link!(amateur, "auf", "primera-divisional-c")
  link!(final, "auf", "c1527")
  link!(season, "wikipedia", "Campeonato Uruguayo de Primera Divisional C 2026")

  AMATEUR_SERIES.each_with_index do |(series, names), i|
    group = inicial.groups.find_or_create_by!(name: series) { |g| g.position = i + 1 }
    link!(group, "auf", { "Serie A" => "c1479", "Serie B" => "c1480", "Serie C" => "c1478" }.fetch(series))
    group_teams = names.map { |name| upsert_team(name, name, nil, AMATEUR_ALIASES.fetch(name, [])) }
    group_teams.each do |team|
      season.participations.find_or_create_by!(team: team)
      group.group_memberships.find_or_create_by!(team: team)
    end
    schedule!(inicial, round_robin(group_teams), starts_on: Date.new(2026, 5, 2), group: group, rng: rng) if sample_matches
  end

  if sample_matches
    finalists = inicial.groups.flat_map { |group| Standings::Table.for_stage(inicial, group: group).first(6).map(&:team) }
    schedule!(final, round_robin(finalists.shuffle(random: rng)), starts_on: Date.new(2026, 7, 18), rng: rng)
  end

  # --- Copa AUF Uruguay ----------------------------------------------------------
  # Built entirely from Wikipedia (Sync::Wikipedia::CupImporter), which also
  # creates the teams and the group memberships; there are no sample matches.
  copa = Competition.find_or_create_by!(slug: "copa") { |c| c.name = "Copa AUF Uruguay"; c.tier = 4 }
  season = copa.seasons.find_or_initialize_by(year: SEASON_YEAR)
  season.update!(current: true)

  groups_stage = season.stages.find_or_initialize_by(slug: "grupos")
  groups_stage.update!(name: "Fase de grupos", position: 1, format: :groups,
                       zones: [ zone(1, 2, "next_round"), zone(3, 3, "best_third") ])
  (1..6).each { |n| groups_stage.groups.find_or_create_by!(name: "Grupo #{n}") { |g| g.position = n } }
  # Round numbers match Sync::Wikipedia::CupImporter::KNOCKOUT_ROUNDS.
  knockout = season.stages.find_or_initialize_by(slug: "eliminatorias")
  knockout.update!(name: "Eliminatorias", position: 2, format: :knockout, current: true,
                   round_names: [ "Primera fase amateur", "Segunda fase", "Octavos de final",
                                  "Cuartos de final", "Semifinales", "Final" ])

  link!(season, "wikipedia_cup", "Copa AUF Uruguay 2026")

  # --- Historical records for the relegation average --------------------------
  CSV.foreach(Rails.root.join("db/data/historical_2025.csv"), headers: true) do |row|
    team = Team.find_by!(slug: row["team_slug"])
    competition = Competition.find_by!(slug: row["competition_slug"])
    record = competition.historical_records.find_or_initialize_by(team: team, year: row["year"].to_i)
    record.update!(points: row["points"].to_i, matches_played: row["matches_played"].to_i)
  end
end

puts "Seeds: #{Competition.count} competiciones, #{Team.count} equipos, #{Match.count} partidos (#{Match.finished.count} jugados)."
