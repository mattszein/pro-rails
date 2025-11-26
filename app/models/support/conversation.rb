module Support
  class Conversation < ApplicationRecord
    self.table_name = "conversations"

    belongs_to :ticket, class_name: "Support::Ticket"
    has_many :messages, class_name: "Support::Message", dependent: :destroy
  end
end
