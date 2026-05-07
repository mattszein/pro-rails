# frozen_string_literal: true

module Avatars
  class Generate
    include Interactor

    class RateLimitExceeded < StandardError; end

    delegate :avatar, :image_model, to: :context

    def call
      check_rate_limit!(avatar.profile)

      prompt = AvatarAi::PromptAssembler.new.assemble(avatar)
      selected_model = image_model.presence || AvatarAiConfig.default_image_model

      avatar.update!(assembled_prompt: prompt, image_model: selected_model)
      avatar.start_generating!

      Avatars::GenerateImageJob.perform_later(avatar.id)

      context.avatar = avatar
    rescue RateLimitExceeded => e
      context.fail!(error: e.message, rate_limited: true)
    rescue Avatar::InvalidTransition, ActiveRecord::RecordInvalid => e
      context.fail!(error: e.message)
    end

    private

    def check_rate_limit!(profile)
      count = Avatar
        .where(profile_id: profile.id)
        .generated_today
        .count

      if count >= AvatarAiConfig.max_generations_per_day
        raise RateLimitExceeded, I18n.t("avatars.errors.rate_limit_exceeded")
      end
    end
  end
end
