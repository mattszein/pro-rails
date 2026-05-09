FactoryBot.define do
  factory :avatar do
    association :profile

    kind { :manual }
    status { :completed }
    dna { {} }

    trait :manual do
      kind { :manual }
      status { :completed }
      dna { {} }
    end

    trait :generated do
      kind { :generated }
      status { :draft }
      add_attribute(:method) { 0 } # guided
      dna_version { 1 }
      dna { {style: "pixel_art", archetype: "explorer"} }
    end

    trait :guided do
      generated
      add_attribute(:method) { 0 }
      dna { {"style" => "pixel_art", "archetype" => "explorer", "color_mood" => "neon_night", "mood" => "bold", "background" => "gradient"} }
    end

    trait :freeform do
      generated
      add_attribute(:method) { 1 }
      dna { {"spark_text" => "a cosmic cat", "style_choice" => "anime", "color_preference" => "vibrant", "background" => "gradient"} }
    end

    trait :generating do
      generated
      status { :generating }
      assembled_prompt { "pixel art avatar, explorer energy" }
    end

    trait :completed_generation do
      generated
      status { :completed }
      assembled_prompt { "pixel art avatar, explorer energy" }
    end

    trait :failed do
      generated
      status { :failed }
    end

    trait :with_image do
      after(:build) do |avatar|
        avatar.image.attach(
          io: StringIO.new(Rails.root.join("spec/fixtures/files/avatar.png").binread),
          filename: "avatar.png",
          content_type: "image/png"
        )
      end
    end

    trait :visible do
      visible { true }
    end

    trait :hidden do
      visible { false }
    end
  end
end
