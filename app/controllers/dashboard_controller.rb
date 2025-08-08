class DashboardController < ApplicationController
  def index
    @current_account = current_account
  end
end
