class AddTranscriptToSupportAiRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :support_ai_runs, :transcript, :jsonb, null: false, default: []
  end
end
