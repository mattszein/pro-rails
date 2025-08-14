module Adminit
  class ApplicationController < ActionController::Base
    default_form_builder CustomFormBuilder
  end
end
