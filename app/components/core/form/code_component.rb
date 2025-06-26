# frozen_string_literal: true

class Core::Form::CodeComponent < ViewComponent::Base
  attr_reader :length, :input_name

  def initialize(form, scope = nil, input_name = "token", length = 6)
    @input_name = scope ? "#{scope}[#{input_name}]" : input_name
    @length = length
  end
end
