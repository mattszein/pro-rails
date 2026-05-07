require "rails_helper"

RSpec.describe AiImage::Generator do
  subject(:generator) { described_class.new(model: "dall-e-3") }

  describe "#generate" do
    context "when successful (url-based provider)" do
      let(:mock_result) { double("result", url: "https://example.com/image.png") }
      let(:image_data) { File.binread(Rails.root.join("spec/fixtures/files/avatar.png")) }
      let(:mock_io) { double("io", read: image_data, content_type: "image/png") }

      before do
        allow(RubyLLM).to receive(:paint).and_return(mock_result)
        allow_any_instance_of(described_class).to receive(:url_based_generate).and_call_original
        allow(URI).to receive_message_chain(:parse, :open).and_return(mock_io)
      end

      it "returns a hash with io and content_type" do
        result = generator.generate("pixel art avatar")
        expect(result[:io]).to be_a(StringIO)
        expect(result[:content_type]).to eq("image/png")
      end

      it "calls RubyLLM.paint with the prompt and model" do
        generator.generate("pixel art avatar")
        expect(RubyLLM).to have_received(:paint).with("pixel art avatar", model: "dall-e-3")
      end
    end

    context "when provider returns no URL" do
      let(:mock_result) { double("result") }

      before do
        allow(RubyLLM).to receive(:paint).and_return(mock_result)
        allow(mock_result).to receive(:respond_to?).with(:url).and_return(false)
        allow(mock_result).to receive(:respond_to?).with(:[]).and_return(false)
      end

      it "raises GenerationError" do
        expect { generator.generate("prompt") }.to raise_error(AiImage::Generator::GenerationError)
      end
    end

    context "when RubyLLM raises error" do
      before do
        allow(RubyLLM).to receive(:paint).and_raise(RubyLLM::Error.new("API error"))
      end

      it "raises GenerationError" do
        expect { generator.generate("prompt") }.to raise_error(AiImage::Generator::GenerationError)
      end
    end
  end
end
