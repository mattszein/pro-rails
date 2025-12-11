module Support
  class AttachmentUploadFormComponent < ApplicationViewComponent
    option :ticket

    def allowed_types
      FileUploadConfig.allowed_content_types_list.join(",")
    end

    def max_files
      FileUploadConfig.max_files_per_ticket
    end
  end
end
