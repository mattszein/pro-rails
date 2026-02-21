module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      # This is only called when NOT using JWT (development/fallback)
      self.current_user = find_verified_account
      if Rails.env.development?
        Rails.logger.info "🔌 RPC Connection established for User #{current_user.id}"
      end
      logger.add_tags "ActionCable", "User #{current_user.id}"
    end

    protected

    def find_verified_account
      if request.session[:account_id].present?
        Account.find_by(id: request.session[:account_id]) || reject_unauthorized_connection
      else
        reject_unauthorized_connection
      end
    end
  end
end
