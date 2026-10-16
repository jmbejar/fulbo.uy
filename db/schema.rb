# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_10_16_040503) do
  create_table "competitions", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "tier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_competitions_on_slug", unique: true
  end

  create_table "external_ids", force: :cascade do |t|
    t.string "source", null: false
    t.string "external_id", null: false
    t.string "identifiable_type", null: false
    t.integer "identifiable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifiable_type", "identifiable_id"], name: "index_external_ids_on_identifiable"
    t.index ["source", "external_id", "identifiable_type"], name: "idx_on_source_external_id_identifiable_type_2e3903d692", unique: true
  end

  create_table "group_memberships", force: :cascade do |t|
    t.integer "group_id", null: false
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "team_id"], name: "index_group_memberships_on_group_id_and_team_id", unique: true
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["team_id"], name: "index_group_memberships_on_team_id"
  end

  create_table "groups", force: :cascade do |t|
    t.integer "stage_id", null: false
    t.string "name", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stage_id"], name: "index_groups_on_stage_id"
  end

  create_table "historical_records", force: :cascade do |t|
    t.integer "team_id", null: false
    t.integer "competition_id", null: false
    t.integer "year", null: false
    t.integer "points", default: 0, null: false
    t.integer "matches_played", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id", "team_id", "year"], name: "idx_on_competition_id_team_id_year_85a84325c8", unique: true
    t.index ["competition_id"], name: "index_historical_records_on_competition_id"
    t.index ["team_id"], name: "index_historical_records_on_team_id"
  end

  create_table "match_reports", force: :cascade do |t|
    t.integer "match_id", null: false
    t.string "source", null: false
    t.integer "home_goals"
    t.integer "away_goals"
    t.integer "home_penalties"
    t.integer "away_penalties"
    t.string "walkover_winner"
    t.boolean "postponed", default: false, null: false
    t.datetime "reported_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id", "source"], name: "index_match_reports_on_match_id_and_source", unique: true
    t.index ["match_id"], name: "index_match_reports_on_match_id"
  end

  create_table "matches", force: :cascade do |t|
    t.integer "stage_id", null: false
    t.integer "group_id"
    t.integer "round"
    t.datetime "kicks_off_at"
    t.integer "home_team_id", null: false
    t.integer "away_team_id", null: false
    t.integer "home_goals"
    t.integer "away_goals"
    t.integer "home_penalties"
    t.integer "away_penalties"
    t.string "status", default: "scheduled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "walkover_winner"
    t.index ["away_team_id"], name: "index_matches_on_away_team_id"
    t.index ["group_id"], name: "index_matches_on_group_id"
    t.index ["home_team_id"], name: "index_matches_on_home_team_id"
    t.index ["stage_id", "round"], name: "index_matches_on_stage_id_and_round"
    t.index ["stage_id"], name: "index_matches_on_stage_id"
  end

  create_table "participations", force: :cascade do |t|
    t.integer "team_id", null: false
    t.integer "season_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["season_id", "team_id"], name: "index_participations_on_season_id_and_team_id", unique: true
    t.index ["season_id"], name: "index_participations_on_season_id"
    t.index ["team_id"], name: "index_participations_on_team_id"
  end

  create_table "points_adjustments", force: :cascade do |t|
    t.integer "team_id", null: false
    t.integer "stage_id", null: false
    t.integer "points", null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stage_id"], name: "index_points_adjustments_on_stage_id"
    t.index ["team_id"], name: "index_points_adjustments_on_team_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.integer "competition_id", null: false
    t.integer "year", null: false
    t.string "official_name"
    t.boolean "current", default: false, null: false
    t.json "annual_zones", null: false
    t.json "relegation_zones", null: false
    t.integer "relegation_years", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id", "year"], name: "index_seasons_on_competition_id_and_year", unique: true
    t.index ["competition_id"], name: "index_seasons_on_competition_id"
  end

  create_table "stages", force: :cascade do |t|
    t.integer "season_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "position", default: 0, null: false
    t.string "format", default: "round_robin", null: false
    t.boolean "counts_for_annual", default: false, null: false
    t.boolean "current", default: false, null: false
    t.json "tiebreakers", null: false
    t.json "zones", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["season_id", "slug"], name: "index_stages_on_season_id_and_slug", unique: true
    t.index ["season_id"], name: "index_stages_on_season_id"
  end

  create_table "team_aliases", force: :cascade do |t|
    t.integer "team_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_team_aliases_on_name", unique: true
    t.index ["team_id"], name: "index_team_aliases_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name"
    t.string "slug", null: false
    t.string "city"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "crest_url"
    t.index ["slug"], name: "index_teams_on_slug", unique: true
  end

  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "teams"
  add_foreign_key "groups", "stages"
  add_foreign_key "historical_records", "competitions"
  add_foreign_key "historical_records", "teams"
  add_foreign_key "match_reports", "matches"
  add_foreign_key "matches", "groups"
  add_foreign_key "matches", "stages"
  add_foreign_key "matches", "teams", column: "away_team_id"
  add_foreign_key "matches", "teams", column: "home_team_id"
  add_foreign_key "participations", "seasons"
  add_foreign_key "participations", "teams"
  add_foreign_key "points_adjustments", "stages"
  add_foreign_key "points_adjustments", "teams"
  add_foreign_key "seasons", "competitions"
  add_foreign_key "stages", "seasons"
  add_foreign_key "team_aliases", "teams"
end
