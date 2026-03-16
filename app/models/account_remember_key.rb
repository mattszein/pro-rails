class AccountRememberKey < ApplicationRecord
  self.table_name = "account_remember_keys"
  self.primary_key = "id"
  belongs_to :account
end
