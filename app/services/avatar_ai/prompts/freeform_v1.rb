# frozen_string_literal: true

module AvatarAi
  module Prompts
    class FreeformV1 < Base
      include Vocabulary

      private

      def parts
        [
          dna["spark_text"],
          AVATAR_SUBJECT,
          dna["style_choice"] && "art style: #{dna["style_choice"]}",
          concept_part,
          color_preference_description(dna["color_preference"]),
          background_description(dna["background"]),
          QUALITY_SUFFIX
        ]
      end

      def concept_part
        return nil unless dna["concept_choice"]
        dna["concepts"]&.at(dna["concept_choice"].to_i)
      end
    end
  end
end
