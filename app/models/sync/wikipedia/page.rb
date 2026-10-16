module Sync
  module Wikipedia
    # Parses an es.wikipedia season or tournament page:
    # - Results: one HTML table per round (Local / Resultado / Visitante /
    #   Fecha ...). Cells with rowspan are expanded. "w/o" marks a walkover,
    #   whose winner is the bold side; "Libre: X" rows are byes.
    # - Standings: {{#invoke:Football table}} invocations in the wikitext,
    #   whose ajustar_puntos_X/hth_X parameters hold points sanctions.
    class Page
      Result = Data.define(:round, :home_name, :away_name, :home_goals, :away_goals, :walkover_winner, :date)
      TableRow = Data.define(:name, :adjustment, :reason)

      SCORE = /\A(\d+)\s*[:\-–]\s*(\d+)/
      WALKOVER = %r{\bw/o\b}i
      DATE = /(\d{1,2}) de ([[:alpha:]]+)/

      def initialize(html:, wikitext:, year:)
        @doc = Nokogiri::HTML(html)
        @wikitext = wikitext
        @year = year
      end

      def results
        @doc.css("table").flat_map { |table| table_results(table) }
      end

      # => [[TableRow, ...], ...], one array per Football table.
      def tables
        @wikitext.scan(/\{\{#invoke:Football table.*?\n\}\}/m).map do |table|
          codes = param(table, "orden_equipo").to_s.split(",").map(&:strip).reject(&:empty?)
          codes.map do |code|
            adjustment = param(table, "ajustar_puntos_#{code}")
            TableRow.new(name: team_name(param(table, "nombre_#{code}")),
                         adjustment: adjustment&.delete("+")&.to_i,
                         reason: clean(param(table, "hth_#{code}")).presence)
          end
        end
      end

      private

      def table_results(table)
        rows = table.css("tr").to_a
        header_index = rows.index { |tr| tr.css("th").map { squish(_1.text) }.then { _1.include?("Local") && _1.include?("Visitante") } }
        return [] unless header_index

        columns = rows[header_index].css("th").map { squish(_1.text) }
        round = rows.first(header_index).filter_map { squish(_1.text)[/Fecha (\d+)/, 1] }.first&.to_i
        expand_rowspans(rows.drop(header_index + 1), columns.size).filter_map do |cells|
          row = columns.zip(cells).to_h
          result(row, round)
        end
      end

      def result(row, round)
        home, away, score = row["Local"], row["Visitante"], row["Resultado"]
        return unless home && away && squish(away.text).present?

        home_goals, away_goals = squish(score&.text).match(SCORE)&.captures&.map(&:to_i)
        walkover = if squish(score&.text).match?(WALKOVER)
          if home.at_css("b") then "home" elsif away.at_css("b") then "away" end
        end
        Result.new(round: round, home_name: team_label(home), away_name: team_label(away),
                   home_goals: home_goals, away_goals: away_goals, walkover_winner: walkover,
                   date: date(squish(row["Fecha"]&.text)))
      end

      # Returns each body row as an array of <td> nodes, one per column,
      # repeating cells that span several rows.
      def expand_rowspans(rows, width)
        carried = {}
        rows.filter_map do |tr|
          cells = tr.css("> td").to_a
          next if cells.empty?

          (0...width).map do |column|
            if carried[column] && carried[column][0].positive?
              carried[column][0] -= 1
              carried[column][1]
            else
              cell = cells.shift
              span = cell&.[]("rowspan").to_i
              carried[column] = [ span - 1, cell ] if span > 1
              cell
            end
          end
        end
      end

      def date(text)
        day, month_name = text.match(DATE)&.captures
        month = I18n.t("date.month_names", locale: :es).index { |name| name&.casecmp?(month_name.to_s) }
        Date.new(@year, month, day.to_i) if day && month
      rescue Date::Error
        nil
      end

      def param(table, name)
        table[/\|\s*#{Regexp.escape(name)}\s*=\s*([^\n]*)/, 1]&.then { |value| value.sub(/\s*\|\s*[\p{Word}]+\s*=.*/, "") }&.strip
      end

      # Drops markers such as "(C)" for the champion.
      def team_label(cell) = squish(cell.text).sub(/\s*\([A-Z]\)\z/, "")

      def team_name(value)
        value = value.to_s
        name = value[/\{\{AUF\|([^}|]+)/, 1] || value[/\[\[(?:[^\]|]*\|)?([^\]]+)\]\]/, 1] || value
        clean(name)
      end

      def clean(value)
        value.to_s.gsub(/<ref[^>]*\/>|<ref.*?(<\/ref>|\z)|<!--.*?-->/m, "").gsub(/\{\{[^}]*\}\}|'''?/, "")
          .gsub(/\[\[(?:[^\]|]*\|)?([^\]]+)\]\]/, '\1').strip
      end

      def squish(text) = text.to_s.gsub(/\[(\d+|nota \d+)\]/, "").gsub(/[[:space:]​]+/, " ").strip
    end
  end
end
