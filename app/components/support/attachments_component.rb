module Support
  class AttachmentsComponent < ApplicationViewComponent
    option :ticket
    option :show_upload_form, default: false

    def attachments
      @ticket.attachments
    end

    def has_attachments?
      attachments.attached?
    end
  end
end
