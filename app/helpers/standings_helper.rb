module StandingsHelper
  ZONE_STYLES = {
    "champion" => "border-l-emerald-500 bg-emerald-50",
    "libertadores" => "border-l-emerald-500 bg-emerald-50",
    "promotion" => "border-l-emerald-500 bg-emerald-50",
    "final" => "border-l-sky-500 bg-sky-50",
    "playoff" => "border-l-sky-500 bg-sky-50",
    "promotion_playoff" => "border-l-amber-500 bg-amber-50",
    "relegation_playoff" => "border-l-orange-500 bg-orange-50",
    "relegation" => "border-l-red-500 bg-red-50"
  }.freeze

  ZONE_DOTS = {
    "champion" => "bg-emerald-500", "libertadores" => "bg-emerald-500", "promotion" => "bg-emerald-500",
    "final" => "bg-sky-500", "playoff" => "bg-sky-500", "promotion_playoff" => "bg-amber-500",
    "relegation_playoff" => "bg-orange-500", "relegation" => "bg-red-500"
  }.freeze

  def zone_at(position, zones)
    Array(zones).find { |zone| position.between?(zone["from"], zone["to"]) }&.fetch("zone")
  end

  def zone_row_class(zone)
    [ "border-l-4", ZONE_STYLES.fetch(zone, "border-l-transparent") ].join(" ")
  end

  def zone_legend(zones)
    keys = Array(zones).map { |zone| zone["zone"] }.uniq
    return if keys.empty?

    tag.ul(class: "mt-3 flex flex-wrap gap-x-4 gap-y-1 text-xs text-slate-600") do
      safe_join(keys.map do |key|
        tag.li(class: "flex items-center gap-1.5") do
          tag.span(class: "inline-block h-3 w-1 #{ZONE_DOTS[key]}") +
            t("zones.#{key}")
        end
      end)
    end
  end

  def signed(number)
    number.positive? ? "+#{number}" : number.to_s
  end
end
