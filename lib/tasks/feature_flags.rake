namespace :feature_flags do
  desc "Materialize a row for every declared feature flag key"
  task sync: :environment do
    FeatureFlag.materialize_declared!
  end
end

# Runs on every deploy (bin/docker-entrypoint calls db:prepare) and every
# local migration, so a newly declared flag appears in Adminit without a
# manual step. `enhance` with a block appends an action, so this runs after
# the schema is up to date rather than before.
#
# Skipped in test: specs own their FeatureFlag rows via factories/registry
# resets, and a row materialized ahead of the run would sit outside every
# example's transaction — invisible to `FeatureFlags::Registry` after the
# first example resets it, but still a real row every table-wide query sees.
unless Rails.env.test?
  Rake::Task["db:prepare"].enhance { Rake::Task["feature_flags:sync"].invoke }
  Rake::Task["db:migrate"].enhance { Rake::Task["feature_flags:sync"].invoke }
end
