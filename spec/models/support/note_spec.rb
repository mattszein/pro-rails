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

  describe "immutability" do
    it "refuses to update a system note" do
      note = create(:note, :system, body: "Original")
      expect(note.update(body: "Changed")).to be(false)
      expect(note.reload.body).to eq("Original")
    end

    it "refuses to destroy a system note directly" do
      note = create(:note, :system)
      expect(note.destroy).to be(false)
      expect(described_class.exists?(note.id)).to be(true)
    end

    it "removes system notes when their ticket is destroyed" do
      note = create(:note, :system)
      expect { note.ticket.destroy }.to change { described_class.where(id: note.id).count }.from(1).to(0)
    end

    it "still updates and destroys internal notes" do
      note = create(:note, body: "Draft")
      expect(note.update(body: "Edited")).to be(true)
      expect(note.reload.body).to eq("Edited")
      expect(note.destroy).to be_truthy
    end
  end
end
