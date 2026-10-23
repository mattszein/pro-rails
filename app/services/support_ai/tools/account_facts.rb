module SupportAi
  module Tools
    # Requester-only facts. Deliberately no email, password or session data.
    class AccountFacts < Base
      description "Facts about the person who opened this ticket: account status, verification, " \
        "member-since date and role. Takes no arguments."

      def execute
        account = ticket.created
        return {error: "Requester unknown"} unless account

        {
          status: account.status,
          verified: account.verified?,
          member_since: account.created_at.to_date.iso8601,
          role: account.role&.name
        }
      end
    end
  end
end
