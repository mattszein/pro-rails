class RodauthMailer < ApplicationMailer
  default to: -> { @rodauth.email_to }, from: -> { @rodauth.email_from }

  def email_auth(name, account_id, key)
    @rodauth = rodauth(name, account_id) { @email_auth_key_value = key }
    @account = @rodauth.rails_account

    mail subject: @rodauth.email_subject_prefix + @rodauth.email_auth_email_subject
  end

  private

  # Default URL options are inherited from Action Mailer, but you can override them
  # ad-hoc by modifying the `rodauth.rails_url_options` hash.
  def rodauth(name, account_id, &block)
    instance = RodauthApp.rodauth(name).allocate
    instance.account_from_id(account_id)
    instance.instance_eval(&block) if block
    instance
  end
end
