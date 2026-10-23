require "rails_helper"

RSpec.describe Support::Note, type: :model do
  it "supports the ai kind without an account" do
    note = create(:note, :ai)
    expect(note.reload).to be_ai
    expect(note.account).to be_nil
  end

  it "keeps internal and system kinds" do
    expect(create(:note)).to be_internal
    expect(create(:note, :system)).to be_system
  end

  it "requires a body" do
    expect(build(:note, body: nil)).not_to be_valid
  end
end
