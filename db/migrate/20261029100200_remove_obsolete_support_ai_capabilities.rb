# suggest_articles, propose_resolution and request_human stopped being switchable capabilities:
# article_ids / resolution_proposed / handoff are now always part of the model's JSON answer.
# Strip the keys from stored playbooks so they stay valid (capabilities must be registered).
# Irreversible on purpose: the keys no longer exist to restore. Historic AiRun snapshots are untouched.
class RemoveObsoleteSupportAiCapabilities < ActiveRecord::Migration[8.1]
  REMOVED = %w[suggest_articles propose_resolution request_human].freeze

  def up
    REMOVED.each do |key|
      execute "UPDATE support_ai_playbooks SET capabilities = array_remove(capabilities, #{connection.quote(key)})"
    end
  end

  def down
    # no-op
  end
end
