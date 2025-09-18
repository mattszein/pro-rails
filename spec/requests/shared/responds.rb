# spec/requests/shared/responds.rb

RSpec.shared_examples "respond with redirect" do
  it "responds with redirect" do
    expect(response).to have_http_status(302)
  end
end

RSpec.shared_examples "respond to success" do
  it "responds with success" do
    expect(response).to have_http_status(:success)
  end
end
