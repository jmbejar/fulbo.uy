# Keeps matches in sync with the external sources:
# - AUF (auf.org.uy) builds the fixture: matches, dates, rounds and scores.
# - Tenfield Estadísticas reports scores (and postponements) soonest.
# - Wikipedia corrects what the others miss: walkovers and points sanctions.
# - Wikipedia is the only source for the Copa AUF Uruguay, whose fixture it builds.
# Each source files a MatchReport per match; Sync::Resolver merges them.
module Sync
  IMPORTERS = {
    "auf" => "Sync::Auf::Importer",
    "tenfield" => "Sync::Tenfield::Importer",
    "wikipedia" => "Sync::Wikipedia::Importer",
    "wikipedia_cup" => "Sync::Wikipedia::CupImporter"
  }.freeze

  def self.run(source, full: false)
    importer = IMPORTERS.fetch(source.to_s).constantize.new(full: full)
    importer.call.tap do |summary|
      Rails.logger.info("[sync:#{source}] #{summary.to_h}")
      Resolver.refresh_live
    end
  end
end
