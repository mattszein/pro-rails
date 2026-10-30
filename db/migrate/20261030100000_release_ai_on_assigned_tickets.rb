# Invariant: an assigned ticket never has the AI engaged (Support::Ticket#ai_not_engaged_while_assigned).
# The old before_save callback enforced it only on assignment updates; this settles any row that
# slipped through (a no-op when none did). Irreversible on purpose: the previous AI state is not kept.
class ReleaseAiOnAssignedTickets < ActiveRecord::Migration[8.1]
  # ai_state integers: analyzing 1, awaiting_user 2, handoff_requested 3, stepped_back 4
  def up
    execute <<~SQL.squish
      UPDATE tickets
      SET ai_state = 4, ai_state_changed_at = NOW()
      WHERE assigned_id IS NOT NULL AND ai_state IN (1, 2, 3)
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
