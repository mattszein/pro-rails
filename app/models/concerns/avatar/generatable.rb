# frozen_string_literal: true

module Avatar::Generatable
  extend ActiveSupport::Concern

  METHODS = {
    "guided" => 0,
    "freeform" => 1
  }.freeze

  GENERATION_STEPS = {
    "guided" => 6,
    "freeform" => 5
  }.freeze

  GUIDED_DNA_FIELDS = %w[style archetype color_mood elements mood background].freeze
  FREEFORM_DNA_FIELDS = %w[spark_text mood_board_selected style_choice concept_choice color_preference].freeze

  included do
    validates :dna_version, presence: true, if: :generated?
    validate :generation_method_present, if: :generated?
  end

  def generation_method
    METHODS.key(self[:method])
  end

  def max_wizard_step
    GENERATION_STEPS[generation_method]
  end

  def wizard_resume_step
    fields = (generation_method == "guided") ? GUIDED_DNA_FIELDS : FREEFORM_DNA_FIELDS
    idx = fields.index { |key| dna[key].blank? }
    idx ? (idx + 1).to_s : nil
  end

  private

  def generation_method_present
    errors.add(:method, :blank) if self[:method].nil?
  end
end
