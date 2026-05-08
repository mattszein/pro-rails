module Settings::AvatarWizard
  Section = Data.define(:dna_field, :i18n_key, :label_i18n, :columns)

  # NavigableStep wraps a wizard step with all context a component needs.
  NavigableStep = Data.define(
    :name,            # String — matches locale key under avatars.guided / avatars.freeform
    :component,       # Symbol — key into StepConfig::COMPONENTS registry
    :step_number,     # Integer
    :total,           # Integer
    :dna_field,       # String or nil
    :columns,         # Integer or nil
    :has_colors,      # Boolean
    :variant,         # Symbol or nil (e.g. :stacked)
    :dynamic_options, # String or nil — DNA key holding runtime options
    :loading_field,   # String or nil — DNA key signalling loading state
    :sections,        # Array<Section> or nil — for compound_select only
    :back_step,       # String or nil — "1".."6"
    :next_step        # String or nil
  ) do
    def final? = next_step.nil?
    def i18n_key = "avatars.#{i18n_namespace}.#{name}"

    private

    def i18n_namespace
      StepConfig::GUIDED_STEP_NAMES.include?(name) ? "guided" : "freeform"
    end
  end

  class StepConfig
    GUIDED_STEP_NAMES = %w[style archetype color_mood elements mood background].freeze
    FREEFORM_STEP_NAMES = %w[spark mood_board style_match remix finish].freeze

    COMPONENTS = {
      select: -> { SelectStepComponent },
      multi_select: -> { MultiSelectStepComponent },
      mood_board: -> { MultiSelectStepComponent },
      compound_select: -> { CompoundSelectStepComponent },
      input: -> { InputStepComponent }
    }.freeze

    STEP_DEFAULTS = {
      has_colors: false, variant: nil, dynamic_options: nil, loading_field: nil, sections: nil
    }.freeze

    GUIDED_STEP_ATTRS = {
      "style" => {component: :select, dna_field: "style", columns: 4},
      "archetype" => {component: :select, dna_field: "archetype", columns: 3},
      "color_mood" => {component: :select, dna_field: "color_mood", columns: 3, has_colors: true},
      "elements" => {component: :multi_select, dna_field: "elements", columns: 3},
      "mood" => {component: :select, dna_field: "mood", columns: 3},
      "background" => {component: :select, dna_field: "background", columns: 4}
    }.freeze

    FINISH_SECTIONS = [
      Section.new(dna_field: "color_preference",
        i18n_key: "avatars.freeform.finish.colors",
        label_i18n: "avatars.freeform.finish.color_label",
        columns: 5),
      Section.new(dna_field: "background",
        i18n_key: "avatars.guided.background.options",
        label_i18n: "avatars.freeform.finish.background_label",
        columns: 4)
    ].freeze

    FREEFORM_STEP_ATTRS = {
      "spark" => {component: :input, dna_field: nil, columns: nil},
      "mood_board" => {component: :mood_board, dna_field: "mood_board_selected", columns: nil,
                       loading_field: "mood_board_prompts"},
      "style_match" => {component: :select, dna_field: "style_choice", columns: 2,
                        dynamic_options: "style_suggestions", loading_field: "style_suggestions"},
      "remix" => {component: :select, dna_field: "concept_choice", columns: 1,
                  variant: :stacked, dynamic_options: "concepts", loading_field: "concepts"},
      "finish" => {component: :compound_select, dna_field: nil, columns: nil, sections: FINISH_SECTIONS}
    }.freeze

    GUIDED_STEPS = GUIDED_STEP_NAMES.each_with_index.to_h do |name, idx|
      num = idx + 1
      total = GUIDED_STEP_NAMES.size
      attrs = STEP_DEFAULTS.merge(GUIDED_STEP_ATTRS[name])
      step = NavigableStep.new(
        name: name, step_number: num, total: total,
        back_step: (idx > 0) ? idx.to_s : nil,
        next_step: (num < total) ? (num + 1).to_s : nil,
        **attrs
      )
      [num.to_s, step]
    end.freeze

    FREEFORM_STEPS = FREEFORM_STEP_NAMES.each_with_index.to_h do |name, idx|
      num = idx + 1
      total = FREEFORM_STEP_NAMES.size
      attrs = STEP_DEFAULTS.merge(FREEFORM_STEP_ATTRS[name])
      step = NavigableStep.new(
        name: name, step_number: num, total: total,
        back_step: (idx > 0) ? idx.to_s : nil,
        next_step: (num < total) ? (num + 1).to_s : nil,
        **attrs
      )
      [num.to_s, step]
    end.freeze

    def self.for(method_name, step_number)
      registry = (method_name == "guided") ? GUIDED_STEPS : FREEFORM_STEPS
      registry.fetch(step_number.to_s) { raise ArgumentError, "Unknown step #{step_number} for #{method_name}" }
    end

    def self.component_class(step)
      factory = COMPONENTS.fetch(step.component) { raise ArgumentError, "Unknown component: #{step.component}" }
      factory.call
    end
  end
end
