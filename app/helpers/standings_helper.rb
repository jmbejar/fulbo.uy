module StandingsHelper
  ZONE_COLORS = {
    "champion" => "bg-zone1", "championship_final" => "bg-zone1", "libertadores" => "bg-zone1", "promotion" => "bg-zone1", "final" => "bg-zone1", "next_round" => "bg-zone1",
    "playoff" => "bg-zone2", "sudamericana" => "bg-zone2", "promotion_playoff" => "bg-zone2", "best_third" => "bg-zone2",
    "relegation_playoff" => "bg-zone3", "relegation" => "bg-zone3"
  }.freeze

  Section = Data.define(:zone, :positions)

  # Splits positions 1..size into runs with the same zone, so each run can be
  # introduced by a label that says what it means.
  def standings_sections(size, zones)
    (1..size).chunk_while { |a, b| zone_at(a, zones) == zone_at(b, zones) }
      .map { |positions| Section.new(zone_at(positions.first, zones), positions) }
  end

  def section_label(section)
    return t("zones.rest") unless section.zone

    first, last = section.positions.minmax
    range = first == last ? "#{first}º" : t("zones.range", from: "#{first}º", to: "#{last}º")
    "#{t("zones.#{section.zone}")} (#{range})"
  end

  def zone_at(position, zones)
    Array(zones).find { |zone| position.between?(zone["from"], zone["to"]) }&.fetch("zone")
  end

  def zone_color(zone) = ZONE_COLORS.fetch(zone, "bg-line")

  def signed(number)
    number.positive? ? "+#{number}" : number.to_s.sub("-", "−")
  end
end
