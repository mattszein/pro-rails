FactoryBot.define do
  factory :ai_playbook, class: "Support::AiPlaybook" do
    sequence(:name) { |n| "Playbook #{n}" }
    enabled { true }
    mode { :assist }

    trait :default do
      is_default { true }
    end

    trait :triage_only do
      mode { :triage_only }
    end

    trait :disabled do
      enabled { false }
    end
  end

  factory :ai_run, class: "Support::AiRun" do
    association :ticket
    run_trigger { :ticket_created }
    step { :triage }
    status { :succeeded }
  end

  factory :note, class: "Support::Note" do
    association :ticket
    association :account
    body { "A note." }
    kind { :internal }

    trait :system do
      account { nil }
      kind { :system }
    end

    trait :ai do
      account { nil }
      kind { :ai }
    end
  end
end
