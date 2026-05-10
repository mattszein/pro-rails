module Core
  module Table
    Filter = Data.define(:type, :param, :options) do
      def initialize(type:, param:, options: nil)
        raise ArgumentError, "unknown filter type: #{type}" unless %i[text select].include?(type)
        raise ArgumentError, "select filter requires :options" if type == :select && options.nil?
        super
      end

      def text? = type == :text
      def select? = type == :select
    end

    Column = Data.define(:label, :renderer, :sort_key, :filter) do
      def initialize(label:, renderer:, sort_key: nil, filter: nil)
        super
      end

      def sortable? = !sort_key.nil?
      def filterable? = !filter.nil?
    end
  end
end
