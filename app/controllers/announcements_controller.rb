class AnnouncementsController < DashboardController
  before_action :set_announcement, only: %i[show]

  def show
  end

  private

  def set_announcement
    @announcement = Announcement.find(params[:id])
  end
end
