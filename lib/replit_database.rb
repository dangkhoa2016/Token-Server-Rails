require 'faraday'
require 'json'

class ReplitDatabase
  def initialize
  end

  def put(key, value)
    return unless key.present?

    value = value.blank? ? '' : value
    value = value.is_a?(String) ? value : JSON.generate(value)
    data = "#{CGI.escape(key)}=#{CGI.escape(value)}"

    begin
      response = client.post('', data)
      if response
        return true if response.status == 200

        puts response.status, response&.body
      end
    rescue => e
      puts 'Error put', e
    end
  end

  def get(key)
    return unless key.present?

    begin
      response = client.get("#{key}")
      if response
        return response if response.status == 200

        puts response.status, response&.body
      end
    rescue => e
      puts 'Error get', e
    end
  end

  def get_body(key)
    begin
      CGI.unescape(get("#{key}")&.body || '')
    rescue => e
      puts 'Error get_body', e
    end
  end

  def get_as_json(key)
    body = get_body(key)
    return unless body.present?

    begin
      JSON.parse(body)
    rescue => e
      puts 'Error get_as_json', e
    end
  end

  def delete(key)
    return false unless key.present?

    begin
      response = client.delete("#{CGI.escape(key)}")
      if response
        return true if response.status == 200

        puts response.status, response&.body
      end
    rescue => e
      puts 'Error delete', e
    end

    false
  end

  def list(prefix = nil)
    begin
      response = client.get("?prefix=#{prefix || ''}")
      if response
        return response.body.split(/\n+|\r+/).reject(&:empty?) if response.status == 200 && response.body.present?

        puts response.status, response&.body
      end
    rescue => e
      puts 'Error list', e
    end
  end

  private

  def client
    @client = Faraday.new(url: ENV['REPLIT_DB_URL'])
  end
end