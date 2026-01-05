class Adminit::AnnouncementsController < Adminit::ApplicationController
  before_action :set_announcement, only: %i[show edit update destroy publish draft]
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
  end

  def create
    authorize!
    @announcement = Announcement.new(announcement_params)
    @announcement.author = current_account

    respond_to do |format|
      if @announcement.save
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, adminit_announcements_path) }
        format.html { redirect_to adminit_announcement_path(@announcement), notice: "Announcement was successfully created." }
        format.json { render :show, status: :created, location: @announcement }
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("announcement_form",
            partial: "adminit/announcements/form",
            locals: {announcement: @announcement}),
            status: :unprocessable_entity
        }
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @announcement.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @announcement.update(announcement_params)
        flash[:notice] = "Announcement was successfully updated."
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, adminit_announcement_path(@announcement)) }
        format.html { redirect_to adminit_announcement_path(@announcement)}
        format.json { render :show, status: :ok, location: @announcement }
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("announcement_form",
            partial: "adminit/announcements/form",
            locals: {announcement: @announcement}),
            status: :unprocessable_entity
        }
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @announcement.errors, status: :unprocessable_entity }
      end
    end
  end

  def publish
    authorize! @announcement, to: :publish?
    if @announcement.update(status: :scheduled)
      redirect_to adminit_announcement_path(@announcement), notice: "Announcement was successfully scheduled for publishing."
    else
      redirect_to adminit_announcement_path(@announcement), alert: "Failed to schedule announcement: #{@announcement.errors.full_messages.join(", ")}"
    end
  end

  def draft
    authorize! @announcement, to: :draft?
    if @announcement.update(status: :draft)
      redirect_to adminit_announcement_path(@announcement), notice: "Announcement was successfully updated as draft."
    else
      redirect_to adminit_announcement_path(@announcement), alert: "Failed to draft announcement: #{@announcement.errors.full_messages.join(", ")}"
    end
  end

  def destroy
    @announcement.destroy!
    respond_to do |format|
      format.html { redirect_to adminit_announcements_path, notice: "Announcement was successfully destroyed." }
      format.json { head :no_content }
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
end
