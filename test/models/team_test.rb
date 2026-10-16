require "test_helper"

class TeamTest < ActiveSupport::TestCase
  test "crest prefers a bundled one and falls back to AUF's" do
    gladiador = Team.new(name: "Gladiador", slug: "gladiador", crest_url: "https://www.auf.org.uy/gladiador.png")
    assert_equal "crests/gladiador.png", gladiador.crest

    peñarol = Team.new(name: "Peñarol", slug: "penarol", crest_url: "https://www.auf.org.uy/penarol.png")
    assert_equal "https://www.auf.org.uy/penarol.png", peñarol.crest

    assert_nil Team.new(name: "Sin Escudo", slug: "sin-escudo").crest
  end
end
