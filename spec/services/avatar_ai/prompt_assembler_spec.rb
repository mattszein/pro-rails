require "rails_helper"

RSpec.describe AvatarAi::PromptAssembler do
  subject(:assembler) { described_class.new }

  describe "#assemble" do
    context "with guided v1 DNA" do
      let(:avatar) do
        build(:avatar, :guided,
          dna: {
            "style" => "pixel_art",
            "archetype" => "explorer",
            "color_mood" => "neon_night",
            "elements" => ["fox", "crystals"],
            "mood" => "bold",
            "background" => "gradient"
          })
      end

      before do
        avatar.write_attribute(:method, 0)
        avatar.dna_version = 1
      end

      it "assembles a prompt string" do
        prompt = assembler.assemble(avatar)
        expect(prompt).to be_a(String)
        expect(prompt).not_to be_empty
      end

      it "includes style description" do
        prompt = assembler.assemble(avatar)
        expect(prompt).to include("pixel art")
      end

      it "includes archetype description" do
        prompt = assembler.assemble(avatar)
        expect(prompt).to include("explorer")
      end

      it "includes color description" do
        prompt = assembler.assemble(avatar)
        expect(prompt).to include("neon")
      end

      it "includes elements" do
        prompt = assembler.assemble(avatar)
        expect(prompt).to include("fox")
        expect(prompt).to include("crystals")
      end

      it "includes background" do
        prompt = assembler.assemble(avatar)
        expect(prompt).to include("gradient")
      end
    end

    context "with freeform v1 DNA" do
      let(:avatar) do
        build(:avatar, :freeform,
          dna: {
            "spark_text" => "a cosmic cat floating in space",
            "style_choice" => "anime",
            "color_preference" => "vibrant",
            "background" => "scene"
          })
      end

      before do
        avatar.write_attribute(:method, 1)
        avatar.dna_version = 1
      end

      it "assembles a freeform prompt" do
        prompt = assembler.assemble(avatar)
        expect(prompt).to include("cosmic cat")
        expect(prompt).to include("anime")
      end
    end

    context "with unknown method/dna_version" do
      let(:avatar) { build(:avatar, :generated) }

      before do
        avatar.write_attribute(:method, 99)
        avatar.dna_version = 99
      end

      it "raises ArgumentError" do
        expect { assembler.assemble(avatar) }.to raise_error(ArgumentError)
      end
    end
  end
end
