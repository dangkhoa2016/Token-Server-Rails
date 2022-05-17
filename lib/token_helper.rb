require 'faraday'
require 'signet/oauth_2/client'

class TokenHelper
  KEY_PREFIX = 'rails::access_token'
  SCOPES = [
    "https://www.googleapis.com/auth/drive.file",
    "https://www.googleapis.com/auth/drive.metadata",
    "https://www.googleapis.com/auth/drive.metadata.readonly",
    "https://www.googleapis.com/auth/drive.readonly",
    "https://www.googleapis.com/auth/drive"
  ]

  def get_account_token_info(account_name, scope = nil)
    account_json = accounts_helper.get_account(account_name)
    unless account_json.present?
      puts "Can not get json for account: #{account_name}"
      return
    end

    service_account_authorization(account_json, scope)
  end

  def get_access_token(account_name, scope = nil)
    token_info = replit_database.get_as_json("#{KEY_PREFIX}_#{account_name}")
    if token_info.present? && token_info['expired_time'].present?
      puts "Get from Repl database for account: #{account_name}"
      return token_info['access_token'] if token_info['expired_time'].to_time - 50.seconds > Time.now
    end

    token_info = get_account_token_info(account_name, scope)
    if token_info.present?
      json = {
        access_token: token_info.access_token.gsub(/[.]+$/, ''),
        expired_time: token_info.expires_at.utc
      }

      puts("Save token for account: #{account_name}")
      replit_database.put("#{KEY_PREFIX}_#{account_name}", json)

      json[:access_token]
    end
  end

  def get_random_token(scope = nil)
    get_access_token(accounts_helper.get_random_account, scope)
  end

  def service_account_authorization(credentials_json, scope = nil)
    scope = SCOPES unless scope.present?
    return unless credentials_json.present?
    authorization = Signet::OAuth2::Client.new(
        :authorization_uri => 'https://accounts.google.com/o/oauth2/auth',
        :token_credential_uri =>  'https://oauth2.googleapis.com/token',
        :audience => 'https://accounts.google.com/o/oauth2/token',
        :scope => scope,
        :issuer => credentials_json['client_id'],
        :signing_key => OpenSSL::PKey::RSA.new(credentials_json['private_key'], nil),
    )
    authorization.fetch_access_token!
    authorization
  end

  private

  def accounts_helper
    @accounts_helper ||= AccountsHelper.new
  end

  def replit_database
    @replit_database ||= ReplitDatabase.new
  end
end
