module AvatarAi
  module Prompts
    class Base
      QUALITY_SUFFIX = "high quality, detailed, centered composition"
      AVATAR_SUBJECT = "digital avatar portrait"

      def initialize(dna)
        @dna = dna
      end

      def call
        parts.compact.join(", ")
      end

      private

      attr_reader :dna

      def parts
        raise NotImplementedError, "#{self.class}#parts must be implemented"
      end
    end
  end
end
