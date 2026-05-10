module Tableable
  extend ActiveSupport::Concern

  private

  def apply_table_params(scope, allowed_sorts: nil, allowed_filters: {}, query: nil, default_sort: nil, default_direction: :desc)
    if query
      allowed_sorts = query.sorts
      allowed_filters = query.filters
    end
    scope = apply_filters(scope, allowed_filters)
    scope = apply_sort(scope, Array(allowed_sorts), default_sort, default_direction)
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
    allowed.each do |param_key, filter_or_scope|
      value = params.dig(:filter, param_key)
      next if value.blank?
      scope = if filter_or_scope.respond_to?(:call)
        filter_or_scope.call(scope, value)
      else
        scope.public_send(filter_or_scope, value)
      end
    end
    scope
  end
end
