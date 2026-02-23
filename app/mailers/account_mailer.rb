class AccountMailer < ApplicationMailer
  def new_announcement
    @user = params[:recipient]
    @title = params[:message]
    @announcement = params[:record]
    mail(to: @user.email, subject: @title)
  end
end
