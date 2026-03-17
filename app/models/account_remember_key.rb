class AccountRememberKey < ApplicationRecord
  self.table_name = "account_remember_keys"
  belongs_to :account, foreign_key: :id
end
