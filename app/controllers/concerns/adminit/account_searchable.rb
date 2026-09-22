# frozen_string_literal: true

# JSON email-search action body, shared by every admin screen that renders
# matching accounts as selectable {value:, text:} options. Each caller
# supplies its own scope narrowing (e.g. excluding accounts already in a
# role, or closed accounts), limit and value shape — this concern owns only
# what is common: strip the query, short-circuit a too-short one, search,
# render. Authorization stays in the caller: this concern does not know
# which policy or resource a caller is guarding.
module Adminit
  module AccountSearchable
    extend ActiveSupport::Concern

    def search_accounts_json(scope: Account.all, limit: 50, value: ->(account) { account.email }, text: ->(account) { account.email })
      query = params[:q].to_s.strip
      return render(json: []) if query.length < 2

      accounts = scope.search_by_email(query).limit(limit)
      render json: accounts.map { |account| {value: value.call(account), text: text.call(account)} }
    end
  end
end
