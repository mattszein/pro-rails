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

    it "registers a widget" do
      described_class.register(
        key: :test_widget,
        resource: :ticket,
        kind: :personal,
        policy_class: "Adminit::TicketPolicy",
        component_class: "Adminit::Dashboard::Tickets::PersonalWidgetComponent",
        turbo_frame_id: "dashboard_test_widget"
      )

      widget = described_class.find(:test_widget)
      expect(widget).to be_present
      expect(widget.resource).to eq(:ticket)
    end

    it "raises on duplicate key" do
      described_class.register(
        key: :test_widget,
        resource: :ticket,
        kind: :personal,
        policy_class: "Adminit::TicketPolicy",
        component_class: "Adminit::Dashboard::Tickets::PersonalWidgetComponent",
        turbo_frame_id: "dashboard_test_widget"
      )

      expect {
        described_class.register(
          key: :test_widget,
          resource: :ticket,
          kind: :personal,
          policy_class: "Adminit::TicketPolicy",
          component_class: "Adminit::Dashboard::Tickets::PersonalWidgetComponent",
          turbo_frame_id: "dashboard_test_widget2"
        )
      }.to raise_error(ArgumentError, /duplicate widget key/)
    end

    it "raises on refresh_interval below 15 seconds" do
      expect {
        described_class.register(
          key: :test_widget,
          resource: :ticket,
          kind: :personal,
          policy_class: "Adminit::TicketPolicy",
          component_class: "Adminit::Dashboard::Tickets::PersonalWidgetComponent",
          turbo_frame_id: "dashboard_test_widget",
          refresh_interval: 10
        )
      }.to raise_error(ArgumentError, /refresh_interval must be at least 15 seconds/)
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
