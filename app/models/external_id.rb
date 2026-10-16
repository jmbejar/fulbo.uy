# Maps a record to its identifier in an external data source, so future
# ingestion jobs can upsert without creating duplicates.
class ExternalId < ApplicationRecord
  belongs_to :identifiable, polymorphic: true

  validates :source, :external_id, presence: true
  validates :external_id, uniqueness: { scope: [ :source, :identifiable_type ] }
end
