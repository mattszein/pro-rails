# frozen_string_literal: true

module Avatars
  class GenerateFreeformContentJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: 5.seconds, attempts: 3

    def perform(avatar_id, step)
      avatar = Avatar.find_by(id: avatar_id)
      return unless avatar

      result = Avatars::GenerateFreeformContent.call(avatar: avatar, step: step)

      if result.failure?
        Rails.logger.warn("Avatars::GenerateFreeformContentJob failed for avatar #{avatar_id}, step #{step}: #{result.error}")
      end
    end
  end
end
