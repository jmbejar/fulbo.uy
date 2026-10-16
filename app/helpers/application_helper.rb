module ApplicationHelper
  # The team's crest from AUF, or an empty shield of the same size while the
  # sync has not learned it yet. Decorative: the name is always next to it.
  def team_crest(team, size: "size-[1.4em]")
    if team.crest_url.present?
      image_tag team.crest_url, alt: "", loading: "lazy", class: "#{size} shrink-0 object-contain"
    else
      tag.span(class: "#{size} shrink-0 rounded-[0.2em_0.2em_0.65em_0.65em] bg-line2", aria: { hidden: true })
    end
  end
end
