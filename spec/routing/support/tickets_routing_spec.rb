require "rails_helper"

RSpec.describe "Support tickets routing", type: :routing do
  it "does not route ticket edit or update (tickets are immutable after creation)" do
    expect(get: "/support/tickets/1/edit").not_to be_routable
    expect(patch: "/support/tickets/1").not_to be_routable
    expect(put: "/support/tickets/1").not_to be_routable
  end

  it "still routes attach_files" do
    expect(post: "/support/tickets/1/attach_files").to route_to(controller: "support/tickets", action: "attach_files", id: "1")
  end
end
