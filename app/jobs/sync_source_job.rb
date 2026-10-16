# Runs one source's importer (see Sync). Scheduled in config/recurring.yml.
# mode: "incremental" (default) or "full" (Tenfield: walk every feed page;
# Wikipedia: parse pages even if their revision didn't change).
class SyncSourceJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(source, *) { "sync-#{source}" }, duration: 30.minutes

  def perform(source, mode = "incremental")
    Sync.run(source, full: mode == "full")
  end
end
