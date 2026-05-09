module Avatars
  class Select
    include Interactor

    delegate :avatar, :profile, to: :context

    def call
      unless avatar.selectable?
        context.fail!(error: I18n.t("avatars.errors.not_selectable"))
        return
      end

      profile.update!(avatar: avatar)
      context.avatar = avatar
    rescue ActiveRecord::RecordInvalid => e
      context.fail!(error: e.message)
    end
  end
end
