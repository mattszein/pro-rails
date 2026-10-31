module Support
  class Ticket
    module Transitions
      extend ActiveSupport::Concern

      # State transitions. Every guard is checked inside `with_lock`, which reloads the row, so a
      # stale instance cannot act on outdated state. Each does one `update!` and writes its own
      # audit notes in the same transaction. `by:` is the acting account.
      def finish!(by:)
        with_lock do
          raise InvalidTransition, I18n.t("ticket.transitions.can_only_finish") unless in_progress? || reopened?
          update!(status: :finished)
          add_note("Ticket finished.", account: by)
        end
        self
      end

      def reopen!(by:)
        with_lock do
          raise InvalidTransition, I18n.t("ticket.transitions.can_only_reopen") unless finished?
          update!(status: :reopened)
          add_note("Ticket reopened.", account: by)
        end
        self
      end

      def request_reopen!(by:, reason: nil)
        with_lock do
          raise InvalidTransition, I18n.t("ticket.transitions.can_only_request_reopen") unless finished?
          update!(status: :reopen_requested)
          add_note(with_reason("Reopen requested.", reason), account: by)
        end
        self
      end

      def accept_reopen!(by:)
        with_lock do
          raise InvalidTransition, I18n.t("ticket.transitions.can_only_accept_reopen") unless reopen_requested?
          update!(status: :reopened)
          add_note("Reopen request accepted.", account: by)
        end
        self
      end

      def reject_reopen!(by:, reason: nil)
        with_lock do
          raise InvalidTransition, I18n.t("ticket.transitions.can_only_reject_reopen") unless reopen_requested?
          update!(status: :closed)
          add_note(with_reason("Reopen request rejected. Ticket closed.", reason), account: by)
        end
        self
      end

      # Hands an unassigned ticket to `to`. Open tickets move to in_progress; reopen_requested and
      # reopened keep their status (the accept/reject flow stays intact). An engaged AI is silenced in
      # the same update, which keeps the "assigned => AI not engaged" invariant.
      def assign!(to:, by:)
        with_lock do
          raise AlreadyAssigned, I18n.t("ticket.transitions.already_assigned") unless assigned_id.nil?
          raise InvalidTransition, I18n.t("ticket.transitions.can_only_take") unless open? || reopen_requested? || reopened?

          released_ai = ai_engaged?
          attributes = {assigned: to}
          attributes[:status] = :in_progress if open?
          attributes[:ai_state] = :stepped_back if released_ai
          update!(attributes)

          add_note((by == to) ? "Ticket taken by #{to.email}." : "Assigned to #{to.email} by #{by.email}.", account: by)
          add_note(AI_STEPPED_BACK_NOTE, account: nil) if released_ai
        end
        self
      end

      def take!(by:) = assign!(to: by, by: by)

      # The assignee steps away. in_progress goes back to open; reopened stays reopened. The AI
      # state is left alone: once a human was involved the AI does not re-engage.
      def unassign!(by:)
        with_lock do
          raise InvalidTransition, I18n.t("ticket.transitions.not_assigned") unless assigned_id.present? && assigned_id == by.id
          raise InvalidTransition, I18n.t("ticket.transitions.can_only_unassign") unless in_progress? || reopened?

          back_to_open = in_progress?
          update!(assigned: nil, status: back_to_open ? :open : status)
          add_note(back_to_open ? "Left the ticket. Back to open." : "Left the ticket.", account: by)
        end
        self
      end

      def start_ai_analysis!
        with_lock do
          startable = (ai_off? || ai_awaiting_user?) && assigned_id.nil?
          raise InvalidTransition, I18n.t("ticket.transitions.can_only_start_ai_analysis") unless startable
          update!(ai_state: :analyzing)
        end
        self
      end

      def disable_ai!
        with_lock do
          raise InvalidTransition, I18n.t("ticket.transitions.can_only_disable_ai") unless ai_analyzing?
          update!(ai_state: :off)
        end
        self
      end

      def await_user_reply!
        with_lock do
          raise InvalidTransition, I18n.t("ticket.transitions.can_only_await_user_reply") unless ai_analyzing?
          update!(ai_state: :awaiting_user)
        end
        self
      end

      def request_ai_handoff!
        with_lock do
          raise InvalidTransition, I18n.t("ticket.transitions.can_only_request_ai_handoff") unless ai_analyzing? || ai_awaiting_user?
          update!(ai_state: :handoff_requested)
        end
        self
      end

      def resolve_with_ai!
        with_lock do
          raise InvalidTransition, I18n.t("ticket.transitions.can_only_resolve_with_ai") unless open? && ai_awaiting_user?
          update!(status: :finished, ai_state: :resolved)
          add_note("Resolved by the user with AI assistance.", account: nil)
        end
        self
      end

      private

      def add_note(body, account:)
        notes.create!(account: account, kind: :system, body: body)
      end

      def with_reason(body, reason)
        reason.present? ? "#{body} Reason: #{reason}" : body
      end
    end
  end
end
