# frozen_string_literal: true

class GenerateAvatarImageJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(avatar_id)
    avatar = Avatar.find_by(id: avatar_id)

    return unless avatar
    return unless avatar.generating?
    return unless avatar.generated?

    generator = AvatarAi::ImageGenerator.new(model: avatar.image_model)
    result = generator.generate(avatar.assembled_prompt)

    extension = result[:content_type].split("/").last.then { |ext| (ext == "jpeg") ? "jpg" : ext }
    filename = "avatar_#{avatar.id}_#{Time.current.to_i}.#{extension}"
    avatar.image.attach(
      io: result[:io],
      filename: filename,
      content_type: result[:content_type]
    )

    avatar.complete!
    avatar.reload
    broadcast_result(avatar)
  rescue AvatarAi::ImageGenerator::GenerationError, Avatar::InvalidTransition => e
    Rails.logger.error("GenerateAvatarImageJob failed for avatar #{avatar_id}: #{e.message}")
    handle_failure(avatar, e.message)
  end

  private

  def handle_failure(avatar, error_message)
    return unless avatar

    begin
      avatar.fail!
    rescue Avatar::InvalidTransition
      # Already in a terminal state, skip
    end

    broadcast_error(avatar, error_message)
  end

  def broadcast_result(avatar)
    Turbo::StreamsChannel.broadcast_replace_to(
      "avatar_#{avatar.id}",
      target: ActionView::RecordIdentifier.dom_id(avatar, "result"),
      partial: "settings/avatars/result",
      locals: {avatar: avatar}
    )
  end

  def broadcast_error(avatar, error_message)
    Turbo::StreamsChannel.broadcast_replace_to(
      "avatar_#{avatar.id}",
      target: ActionView::RecordIdentifier.dom_id(avatar, "result"),
      partial: "settings/avatars/generation_error",
      locals: {avatar: avatar, error: error_message}
    )
  end
end
