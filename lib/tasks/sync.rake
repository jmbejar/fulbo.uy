namespace :sync do
  desc "Import the fixture and results from auf.org.uy"
  task auf: :environment do
    puts "auf: #{Sync.run("auf").to_h}"
  end

  desc "Import results from Tenfield Estadísticas (FULL=1 walks every feed page)"
  task tenfield: :environment do
    puts "tenfield: #{Sync.run("tenfield", full: ENV["FULL"].present?).to_h}"
  end

  desc "Import walkovers and sanctions from Wikipedia (FULL=1 ignores unchanged revisions)"
  task wikipedia: :environment do
    puts "wikipedia: #{Sync.run("wikipedia", full: ENV["FULL"].present?).to_h}"
  end

  desc "Build the Copa AUF Uruguay from Wikipedia (FULL=1 ignores unchanged revisions)"
  task wikipedia_cup: :environment do
    puts "wikipedia_cup: #{Sync.run("wikipedia_cup", full: ENV["FULL"].present?).to_h}"
  end

  desc "Run every source in order, fully"
  task all: :environment do
    %w[auf tenfield wikipedia wikipedia_cup].each { |source| puts "#{source}: #{Sync.run(source, full: true).to_h}" }
  end
end
