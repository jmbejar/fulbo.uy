require "test_helper"

class TeamTest < ActiveSupport::TestCase
  test "crest prefers AUF's and falls back to a bundled one" do
    gladiador = Team.new(name: "Gladiador", slug: "gladiador")
    assert_equal "crests/gladiador.png", gladiador.crest

    gladiador.crest_url = "https://www.auf.org.uy/gladiador.png"
    assert_equal "https://www.auf.org.uy/gladiador.png", gladiador.crest

    assert_nil Team.new(name: "Sin Escudo", slug: "sin-escudo").crest
  end
end
