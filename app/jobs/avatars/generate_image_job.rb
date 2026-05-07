# frozen_string_literal: true

module Avatars
  class GenerateImageJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    def perform(avatar_id)
      avatar = Avatar.find_by(id: avatar_id)
      return unless avatar
      return unless avatar.generating?
      return unless avatar.generated?

      result = Avatars::GenerateImage.call(avatar: avatar)

      if result.failure?
        Rails.logger.warn("Avatars::GenerateImageJob failed for avatar #{avatar_id}: #{result.error}")
      end
    end
  end
end
