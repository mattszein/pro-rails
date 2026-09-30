require "rails_helper"

RSpec.describe Adminit::BreadcrumbsHelper, type: :helper do
  def stub_request_context(controller:, action:)
    allow(helper).to receive(:controller_name).and_return(controller)
    allow(helper).to receive(:action_name).and_return(action)
  end

  it "returns only the Dash crumb on the dashboard index" do
    stub_request_context(controller: "dashboards", action: "index")

    trail = helper.adminit_breadcrumb_trail

    expect(trail.map(&:label)).to eq(["Dash"])
    expect(trail.first.icon).to eq("home")
  end

  it "returns Dash and the resource crumb (both linked) on a resource index" do
    stub_request_context(controller: "tickets", action: "index")

    trail = helper.adminit_breadcrumb_trail

    expect(trail.map(&:label)).to eq(["Dash", "Tickets"])
    expect(trail.map(&:path)).to eq([adminit_root_path, adminit_tickets_path])
  end

  it "appends the record breadcrumb_title as an unlinked leaf on show" do
    stub_request_context(controller: "tickets", action: "show")
    record = double(breadcrumb_title: "#42 Foo")
    helper.instance_variable_set(:@ticket, record)

    trail = helper.adminit_breadcrumb_trail

    expect(trail.map(&:label)).to eq(["Dash", "Tickets", "#42 Foo"])
    expect(trail.last.path).to be_nil
  end

  it "returns Dash and the resource crumb (both linked) for feature flags" do
    stub_request_context(controller: "feature_flags", action: "index")

    trail = helper.adminit_breadcrumb_trail

    expect(trail.map(&:label)).to eq(["Dash", "Feature Flags"])
    expect(trail.map(&:path)).to eq([adminit_root_path, adminit_feature_flags_path])
  end

  it "appends the flag's breadcrumb_title as an unlinked leaf on show" do
    stub_request_context(controller: "feature_flags", action: "show")
    record = double(breadcrumb_title: "New dashboard")
    helper.instance_variable_set(:@feature_flag, record)

    trail = helper.adminit_breadcrumb_trail

    expect(trail.map(&:label)).to eq(["Dash", "Feature Flags", "New dashboard"])
    expect(trail.last.path).to be_nil
  end

  it "returns Dash and the resource crumb (both linked) for audiences" do
    stub_request_context(controller: "audiences", action: "index")

    trail = helper.adminit_breadcrumb_trail

    expect(trail.map(&:label)).to eq(["Dash", "Audiences"])
    expect(trail.map(&:path)).to eq([adminit_root_path, adminit_audiences_path])
  end

  it "appends the audience's breadcrumb_title as an unlinked leaf on show" do
    stub_request_context(controller: "audiences", action: "show")
    record = double(breadcrumb_title: "Beta testers")
    helper.instance_variable_set(:@audience, record)

    trail = helper.adminit_breadcrumb_trail

    expect(trail.map(&:label)).to eq(["Dash", "Audiences", "Beta testers"])
    expect(trail.last.path).to be_nil
  end

  it "falls back to the record id when breadcrumb_title is not defined" do
    stub_request_context(controller: "roles", action: "show")
    record = double(id: 7)
    helper.instance_variable_set(:@role, record)

    trail = helper.adminit_breadcrumb_trail

    expect(trail.map(&:label)).to eq(["Dash", "Roles", "#7"])
  end

  it "keeps the trail as Dash and the resource when the show record is missing" do
    stub_request_context(controller: "accounts", action: "show")

    trail = helper.adminit_breadcrumb_trail

    expect(trail.map(&:label)).to eq(["Dash", "Accounts"])
  end

  it "returns only Dash for excluded actions" do
    %w[edit new create take new_reject_reopen account_select].each do |action|
      stub_request_context(controller: "tickets", action: action)

      expect(helper.adminit_breadcrumb_trail.map(&:label)).to eq(["Dash"])
    end
  end

  it "returns only Dash for unknown controllers" do
    stub_request_context(controller: "dashboard_widgets", action: "show")

    expect(helper.adminit_breadcrumb_trail.map(&:label)).to eq(["Dash"])
  end
end
