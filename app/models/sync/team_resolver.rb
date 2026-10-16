module Sync
  # Maps a team as a source names it to one of our teams. Names are compared
  # by name and TeamAlias, ignoring case, accents and punctuation; there is no
  # fuzzy matching ("Cerro" must never become "Cerro Largo"), so new spellings
  # need a TeamAlias. When the source also gives a stable id (AUF club slugs),
  # it is remembered as an ExternalId the first time the name matches.
  class TeamResolver
    attr_reader :unresolved

    def self.normalize(name) = I18n.transliterate(name.to_s).downcase.gsub(/[^a-z0-9]/, "")

    def initialize(source:, teams:)
      @source = source
      @teams = teams.includes(:team_aliases).to_a
      @unresolved = Set.new
    end

    def resolve(name, external_id: nil)
      team = (by_external_id(external_id) if external_id) || by_name(name)
      if team.nil?
        @unresolved << name
      elsif external_id && !by_external_id(external_id)
        team.external_ids.create!(source: @source, external_id: external_id)
        known_ids[external_id] = team
      end
      team
    end

    private

    def by_external_id(external_id) = known_ids[external_id]

    def known_ids
      @known_ids ||= ExternalId.where(source: @source, identifiable_type: "Team", identifiable_id: @teams.map(&:id))
        .to_h { |row| [ row.external_id, @teams.find { |team| team.id == row.identifiable_id } ] }
    end

    def by_name(name)
      matches = names_index[self.class.normalize(name)]
      matches.first if matches&.one?
    end

    def names_index
      @names_index ||= @teams.each_with_object(Hash.new { |h, k| h[k] = [] }) do |team, index|
        [ team.name, team.short_name, *team.team_aliases.map(&:name) ].compact.map { self.class.normalize(_1) }.uniq
          .each { |key| index[key] << team }
      end
    end
  end
end
