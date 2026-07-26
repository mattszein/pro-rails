module AvatarAi
  module Prompts
    class GuidedV1 < Base
      include Vocabulary

      private

      def parts
        [
          style_description(dna["style"]),
          archetype_description(dna["archetype"]),
          AVATAR_SUBJECT,
          mood_description(dna["mood"]),
          color_description(dna["color_mood"], custom_colors: dna["custom_colors"]),
          elements_description(dna["elements"]),
          background_description(dna["background"]),
          QUALITY_SUFFIX
        ]
      end
    end
  end
end
