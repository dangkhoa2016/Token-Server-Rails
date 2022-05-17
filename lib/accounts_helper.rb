require 'faraday'

class AccountsHelper
  def initialize
  end

  def get_account(account_name)
    return unless account_name.present?

    begin
      response = client.get(account_name)
      if response
        return response.body if response.status == 200

        puts response.status, response&.body
      end
    rescue => e
      puts 'Error get_account', e
    end
  end

  def account_names
    Rails.cache.fetch(cache_key, expires_in: 1.day) do
      puts 'account_names key expires'
      get_accounts
    end
  end

  def get_random_account
    account_names.sample
  end

  def get_random_json_account
    get_account(get_random_account)
  end

  private

  def get_accounts
    begin
      response = client.get('list')
      if response
        return response.body if response.status == 200

        puts response.status, response&.body
      end
    rescue => e
      puts 'Error get_accounts', e
    end
  end

  def client
    @client ||= Faraday.new(url: "#{ENV['BASE_URL']}/accounts") do |faraday|
      faraday.response :json
    end
  end

  def cache_key
    'AccountsHelper-account_names'
  end
end
