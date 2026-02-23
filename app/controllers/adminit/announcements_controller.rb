class Adminit::AnnouncementsController < Adminit::ApplicationController
  before_action :set_announcement, only: %i[show edit update destroy schedule unschedule]
  verify_authorized

  def index
    authorize!
    @announcements = Announcement.all
  end

  def show
  end

  def new
    authorize!
    @announcement = Announcement.new
  end

  def edit
    unless @announcement.editable?
      respond_error("Cannot edit this announcement.")
    end
  end

  def create
    authorize!
    @announcement = Announcement.new(announcement_params)
    @announcement.author = current_account
    if @announcement.save
      respond_success(resource_message(:created, @announcement), adminit_announcement_path(@announcement))
    else
      respond_form_error(:new)
    end
  end

  def update
    authorize! @announcement

    if @announcement.update(announcement_params)
      respond_success(resource_message(:updated, @announcement), adminit_announcement_path(@announcement))
    else
      respond_form_error(:edit)
    end
  end

  def schedule
    result = Announcements::Schedule.call(announcement: @announcement)
    if result.success?
      respond_success(
        "Announcement scheduled for #{@announcement.scheduled_at.strftime("%B %d, %Y at %I:%M %p")}.",
        adminit_announcement_path(@announcement)
      )
    else
      respond_error(result.error)
    end
  end

  def unschedule
    result = Announcements::Unschedule.call(announcement: @announcement)
    if result.success?
      respond_success("Announcement was unscheduled.", adminit_announcement_path(@announcement))
    else
      respond_error(result.error)
    end
  end

  def destroy
    if @announcement.destroy
      respond_success(resource_message(:deleted, @announcement), adminit_announcements_path)
    else
      respond_error(@announcement.errors.full_messages.to_sentence)
    end
  end

  private

  def set_announcement
    @announcement = Announcement.find(params[:id])
    authorize! @announcement
  end

  def announcement_params
    params.require(:announcement).permit(:title, :body, :scheduled_at)
  end

  def respond_success(message, path)
    respond_to do |format|
      format.html { redirect_to path, notice: message }
      format.turbo_stream do
        flash[:notice] = message
        render turbo_stream: turbo_stream.action(:redirect, path)
      end
      format.json { render :show, status: :ok, location: @announcement }
    end
  end

  def respond_error(message)
    respond_to do |format|
      format.html { redirect_back fallback_location: adminit_announcements_path, alert: message }
      format.turbo_stream do
        flash[:alert] = message
        render turbo_stream: turbo_stream.action(:redirect, request.referer || adminit_announcements_path)
      end
      format.json { render json: @announcement.errors, status: :unprocessable_content }
    end
  end

  def respond_form_error(action)
    respond_to do |format|
      format.html { render action, status: :unprocessable_content }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "announcement_form",
          partial: "adminit/announcements/form",
          locals: {announcement: @announcement}
        ), status: :unprocessable_content
      end
    end
  end
end
