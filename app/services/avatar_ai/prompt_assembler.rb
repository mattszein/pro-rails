# frozen_string_literal: true

module AvatarAi
  class PromptAssembler
    class UnknownStrategy < StandardError; end

    STRATEGIES = {
      ["guided", 1] => "AvatarAi::Prompts::GuidedV1",
      ["freeform", 1] => "AvatarAi::Prompts::FreeformV1"
    }.freeze

    def assemble(avatar)
      key = [avatar.generation_method, avatar.dna_version]
      strategy_class = STRATEGIES.fetch(key) do
        raise UnknownStrategy, "No prompt strategy for method=#{key[0]}, dna_version=#{key[1]}"
      end
      strategy_class.constantize.new(avatar.dna).call
    end
  end
end
