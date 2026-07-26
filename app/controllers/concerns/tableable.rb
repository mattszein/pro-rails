module Tableable
  extend ActiveSupport::Concern

  private

  # `columns` is the same array handed to Core::TableComponent — it is the single
  # declaration of what this table exposes to the request.
  def apply_table_params(scope, columns:, default_sort: nil, default_direction: :desc)
    scope = apply_filters(scope, column_filters(scope.model, columns))
    scope = apply_sort(scope, columns.filter_map(&:sort_key), default_sort, default_direction)
    pagy(scope)
  end

  def column_filters(model, columns)
    columns.filter_map(&:filter).to_h do |filter|
      [filter.param, filter.scope || equality_filter(model, filter.param)]
    end
  end

  def equality_filter(model, param)
    unless model.column_names.include?(param.to_s)
      raise ArgumentError, "filter :#{param} on #{model} needs a scope: (no such column)"
    end
    ->(rel, value) { rel.where(param => value) }
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
