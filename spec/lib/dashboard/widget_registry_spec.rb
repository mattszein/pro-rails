require "rails_helper"

RSpec.describe Dashboard::WidgetRegistry do
  describe ".register" do
    before do
      # Clear any previously registered test widgets
      described_class.instance_variable_get(:@widgets).delete(:test_widget)
    end

    after do
      described_class.instance_variable_get(:@widgets).delete(:test_widget)
    end

    def base_attrs
      {
        key: :test_widget,
        resource: :ticket,
        kind: :personal,
        policy_class: "Adminit::TicketPolicy",
        component_class: "Adminit::Dashboard::Tickets::PersonalWidgetComponent"
      }
    end

    it "registers a widget" do
      described_class.register(**base_attrs)

      widget = described_class.find(:test_widget)
      expect(widget).to be_present
      expect(widget.resource).to eq(:ticket)
    end

    it "defaults span to :full" do
      described_class.register(**base_attrs)
      expect(described_class.find(:test_widget).span).to eq(:full)
    end

    it "accepts an explicit span" do
      # :permission has no real registered widgets, so there's no sibling span to conflict with.
      described_class.register(**base_attrs, resource: :permission, span: :half)
      expect(described_class.find(:test_widget).span).to eq(:half)
    end

    it "derives turbo_frame_id from the key" do
      described_class.register(**base_attrs)
      expect(described_class.find(:test_widget).turbo_frame_id).to eq("dashboard_test_widget")
    end

    it "defaults view_all_params to nil" do
      described_class.register(**base_attrs)
      expect(described_class.find(:test_widget).view_all_params).to be_nil
    end

    it "accepts view_all_params" do
      described_class.register(**base_attrs, view_all_params: {assignee: "me"})
      expect(described_class.find(:test_widget).view_all_params).to eq({assignee: "me"})
    end

    it "raises on duplicate key" do
      described_class.register(**base_attrs)

      expect {
        described_class.register(**base_attrs)
      }.to raise_error(ArgumentError, /duplicate widget key/)
    end

    it "raises on refresh_interval below 15 seconds" do
      expect {
        described_class.register(**base_attrs, refresh_interval: 10)
      }.to raise_error(ArgumentError, /refresh_interval must be at least 15 seconds/)
    end

    it "raises when span disagrees with an already-registered widget for the same resource" do
      described_class.register(**base_attrs, resource: :permission, span: :half)

      expect {
        described_class.register(**base_attrs.merge(key: :test_widget_2), resource: :permission, span: :full)
      }.to raise_error(ArgumentError, /has span :full.*already registered.*span :half/)

      described_class.instance_variable_get(:@widgets).delete(:test_widget_2)
    end
  end

  describe ".for_resource" do
    it "returns widgets for a given resource" do
      widgets = described_class.for_resource(:ticket)
      expect(widgets.map(&:resource)).to all(eq(:ticket))
    end
  end

  describe ".for_keys" do
    it "returns widgets for given keys" do
      widgets = described_class.for_keys([:tickets_personal, :tickets_general])
      expect(widgets.map(&:key)).to contain_exactly(:tickets_personal, :tickets_general)
    end

    it "silently skips unknown keys" do
      widgets = described_class.for_keys([:tickets_personal, :unknown_key])
      expect(widgets.map(&:key)).to contain_exactly(:tickets_personal)
    end
  end
end
