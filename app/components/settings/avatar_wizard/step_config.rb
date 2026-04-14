# frozen_string_literal: true

module Settings::AvatarWizard
  class StepConfig
    GUIDED_STEPS = {
      "1" => {component: :select, step: 1, total: 6, i18n_key: "avatars.guided.step1",
              dna_field: "style", columns: 4, next_step: "2", back_step: nil},
      "2" => {component: :select, step: 2, total: 6, i18n_key: "avatars.guided.step2",
              dna_field: "archetype", columns: 3, next_step: "3", back_step: "1"},
      "3" => {component: :select, step: 3, total: 6, i18n_key: "avatars.guided.step3",
              dna_field: "color_mood", columns: 3, has_colors: true, next_step: "4", back_step: "2"},
      "4" => {component: :multi_select, step: 4, total: 6, i18n_key: "avatars.guided.step4",
              dna_field: "elements", columns: 3, next_step: "5", back_step: "3"},
      "5" => {component: :select, step: 5, total: 6, i18n_key: "avatars.guided.step5",
              dna_field: "mood", columns: 3, next_step: "6", back_step: "4"},
      "6" => {component: :select, step: 6, total: 6, i18n_key: "avatars.guided.step6",
              dna_field: "background", columns: 4, next_step: nil, back_step: "5", final_step: true}
    }.freeze

    FREEFORM_STEPS = {
      "1" => {component: :input, step: 1, total: 5, i18n_key: "avatars.freeform.step1",
              next_step: "2", back_step: nil},
      "2" => {component: :mood_board, step: 2, total: 5, i18n_key: "avatars.freeform.step2",
              dna_field: "mood_board_selected", next_step: "3", back_step: "1",
              loading_field: "mood_board_prompts"},
      "3" => {component: :select, step: 3, total: 5, i18n_key: "avatars.freeform.step3",
              dna_field: "style_choice", columns: 2, next_step: "4", back_step: "2",
              dynamic_options: "style_suggestions", loading_field: "style_suggestions"},
      "4" => {component: :select, step: 4, total: 5, i18n_key: "avatars.freeform.step4",
              dna_field: "concept_choice", columns: 1, variant: :stacked,
              next_step: "5", back_step: "3",
              dynamic_options: "concepts", loading_field: "concepts"},
      "5" => {component: :compound_select, step: 5, total: 5, i18n_key: "avatars.freeform.step5",
              next_step: nil, back_step: "4", final_step: true,
              sections: [
                {dna_field: "color_preference", i18n_key: "avatars.freeform.step5.colors",
                 label_i18n: "avatars.freeform.step5.color_label", columns: 5},
                {dna_field: "background", i18n_key: "avatars.guided.step6.options",
                 label_i18n: "avatars.freeform.step5.background_label", columns: 4}
              ]}
    }.freeze

    def self.for(method_name, step)
      registry = (method_name == "guided") ? GUIDED_STEPS : FREEFORM_STEPS
      registry.fetch(step.to_s)
    end

    def self.component_class(config)
      case config[:component]
      when :select then SelectStepComponent
      when :multi_select, :mood_board then MultiSelectStepComponent
      when :input then InputStepComponent
      when :compound_select then CompoundSelectStepComponent
      end
    end
  end
end
