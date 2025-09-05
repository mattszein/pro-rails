FactoryBot.define do
  factory :permission do
    resource { Adminit::ApplicationPolicy.identifier }
    roles { [create(:role)] }
  end
end
