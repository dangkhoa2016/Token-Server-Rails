class TokenController < ApplicationController
  def token
    type = params[:type]&.downcase.presence || 'access_token'
    scope = params[:scope]
    scope = scope.split(',').reject(&:blank?) if scope.present?
    account = params[:account]

    begin
      if type == 'account_json'
        account_json = accounts_helper.get_account(account)
        return render json: account_json if account_json.present?
      elsif type == 'token_info'
        token_info = token_helper.get_account_token_info(account, scope)
        return render json: {
          expires_at: token_info.expires_at,
          issued_at: token_info.issued_at,
          access_type: token_info.access_type,
          expiry: token_info.expiry,
          access_token: token_info.access_token.gsub(/[.]+$/, ''),
          refresh_token: token_info.refresh_token,
          grant_type: token_info.grant_type,
          scope: token_info.scope
        } if token_info.present?
      else
        token = token_helper.get_access_token(account, scope)
        return render plain: token if token.present?
      end

      render json: { error: "Account: #{account} does not exists." }
    rescue => ex
      render_error(ex)
    end
  end

  def random
    scope = params[:scope]
    scope = scope.split(',').reject(&:blank?) if scope.present?

    begin
      render plain: token_helper.get_random_token(scope)
    rescue => ex
      render_error(ex)
    end
  end

  private

  def token_helper
    @token_helper ||= TokenHelper.new
  end

  def accounts_helper
    @accounts_helper ||= AccountsHelper.new
  end
end
