module Avatars
  class Evolve
    include Interactor

    class RateLimitExceeded < StandardError; end

    delegate :avatar, to: :context

    def call
      check_rate_limit!(avatar.profile)

      unless avatar.evolvable?
        context.fail!(error: I18n.t("avatars.errors.not_evolvable"))
        return
      end

      evolved = Avatar.create!(
        profile: avatar.profile,
        kind: :generated,
        status: :draft,
        method: avatar.read_attribute(:method),
        dna_version: avatar.dna_version,
        dna: avatar.dna.dup,
        image_model: avatar.image_model
      )

      context.avatar = evolved
    rescue RateLimitExceeded => e
      context.fail!(error: e.message, rate_limited: true)
    rescue ActiveRecord::RecordInvalid => e
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
