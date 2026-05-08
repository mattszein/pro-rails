
module Avatars
  class Upload
    include Interactor

    delegate :profile, :image_file, to: :context

    def call
      ActiveRecord::Base.transaction do
        avatar = Avatar.new(
          profile: profile,
          kind: :manual,
          status: :completed,
          dna: {}
        )

        validate_image!(image_file)
        avatar.image.attach(image_file)
        avatar.save!

        profile.update!(avatar: avatar)

        context.avatar = avatar
      end
    rescue ActiveRecord::RecordInvalid, ArgumentError => e
      context.fail!(error: e.message)
    end

    private

    def validate_image!(file)
      return unless file

      content_type = file.respond_to?(:content_type) ? file.content_type : ""
      allowed = %w[image/jpeg image/png image/gif image/webp]
      unless allowed.include?(content_type)
        raise ArgumentError, I18n.t("avatars.errors.invalid_content_type")
      end

      byte_size = file.respond_to?(:size) ? file.size : 0
      if byte_size > 10.megabytes
        raise ArgumentError, I18n.t("avatars.errors.file_too_large")
      end
    end
  end
end
