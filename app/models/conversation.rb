class Conversation < ApplicationRecord
  belongs_to :ticket
  has_many :messages, dependent: :destroy
end
