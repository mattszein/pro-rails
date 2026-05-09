module Tableable
  extend ActiveSupport::Concern

  private

  def apply_table_params(scope, allowed_sorts:, allowed_filters: {}, default_sort: nil, default_direction: :desc)
    scope = apply_filters(scope, allowed_filters)
    scope = apply_sort(scope, allowed_sorts, default_sort, default_direction)
    pagy(scope)
  end

  def apply_sort(scope, allowed, default, default_direction)
    requested = params[:sort]&.to_sym
    column = allowed.include?(requested) ? requested : default
    direction = case params[:direction]
    when "asc" then :asc
    when "desc" then :desc
    else default_direction
    end
    column ? scope.reorder(column => direction) : scope
  end

  def apply_filters(scope, allowed)
    allowed.each do |param_key, scope_method|
      value = params.dig(:filter, param_key)
      next if value.blank?
      scope = scope.public_send(scope_method, value)
    end
    scope
  end
end
