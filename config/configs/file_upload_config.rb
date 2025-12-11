# frozen_string_literal: true

class FileUploadConfig < ApplicationConfig
  # Default values for file upload configuration
  attr_config :max_file_size_mb,
    :allowed_content_types,
    :max_files_per_ticket,
    max_file_size_mb: 2,
    allowed_content_types: %w[
      image/png
      image/jpeg
      image/jpg
      image/gif
      image/webp
      application/pdf
    ],
    max_files_per_ticket: 10

  def max_file_size_bytes
    max_file_size_mb * 1024 * 1024
  end

  def allowed_content_types_list
    allowed_content_types.is_a?(Array) ? allowed_content_types : allowed_content_types.split(",").map(&:strip)
  end
end
