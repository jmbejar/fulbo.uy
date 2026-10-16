module ApplicationHelper
  # Where each competition's navbar link lands: the table people follow most,
  # the Clausura in Primera, the annual one in Segunda and the Torneo Final
  # in Primera Amateur.
  def competition_nav_path(competition)
    case competition.slug
    when "primera" then competition_stage_path(competition, "clausura", view: "standings")
    when "segunda" then annual_competition_path(competition)
    when "amateur" then competition_stage_path(competition, "final", view: "standings")
    else competition_path(competition)
    end
  end

  # The team's crest (AUF's or bundled), or an empty shield of the same size
  # while we have none. Decorative: the name is always next to it.
  def team_crest(team, size: "size-[1.4em]")
    if (crest = team.crest)
      image_tag crest, alt: "", loading: "lazy", class: "#{size} shrink-0 object-contain"
    else
      tag.span(class: "#{size} shrink-0 rounded-[0.2em_0.2em_0.65em_0.65em] bg-line2", aria: { hidden: true })
    end
  end
end
