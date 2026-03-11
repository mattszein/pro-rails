FactoryBot.define do
  factory :permission do
    resource { :application }
    roles { [create(:role)] }
  end
end
