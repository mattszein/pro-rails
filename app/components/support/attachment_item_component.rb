module Support
  class AttachmentItemComponent < ApplicationViewComponent
    option :attachment

    def image?
      attachment.content_type.start_with?("image/")
    end

    def file_size
      helpers.number_to_human_size(attachment.byte_size)
    end

    def download_url
      helpers.rails_blob_path(attachment, disposition: "attachment")
    end

    def filename
      attachment.filename.to_s
    end
  end
end
