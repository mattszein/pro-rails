module Avatars
  class GenerateImage
    include Interactor

    delegate :avatar, to: :context

    def call
      result = AiImage::Generator.new(model: avatar.image_model).generate(avatar.assembled_prompt)

      extension = result[:content_type].split("/").last.then { |ext| (ext == "jpeg") ? "jpg" : ext }
      filename = "avatar_#{avatar.id}_#{Time.current.to_i}.#{extension}"
      avatar.image.attach(io: result[:io], filename: filename, content_type: result[:content_type])

      avatar.complete!
      avatar.reload

      broadcast_result
    rescue AiImage::Generator::GenerationError, Avatar::InvalidTransition => e
      context.fail!(error: e.message)
      handle_failure(e.message)
    end

    private

    def broadcast_result
      Turbo::StreamsChannel.broadcast_replace_to(
        "avatar_#{avatar.id}",
        target: ActionView::RecordIdentifier.dom_id(avatar, "result"),
        partial: "settings/avatars/result",
        locals: {avatar: avatar}
      )
    end

    def handle_failure(error_message)
      begin
        avatar.fail!
      rescue Avatar::InvalidTransition
        # Already in a terminal state
      end

      Turbo::StreamsChannel.broadcast_replace_to(
        "avatar_#{avatar.id}",
        target: ActionView::RecordIdentifier.dom_id(avatar, "result"),
        partial: "settings/avatars/generation_error",
        locals: {avatar: avatar, error: error_message}
      )
    end
  end
end
