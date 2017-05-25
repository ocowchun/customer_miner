require 'httparty'
require 'csv'
require 'json'

module CustomerMiner
  class Query
    def initialize(file:, secret_key:)
      @file = file
      @secret_key = secret_key
    end

    def perform
      domains = extract_domains
    end

    private

    def extract_domains
      reg = /^#.*/
      rows = CSV.read(@file, headers: true, skip_lines: reg)
      rows.map { |row| row['Clearbit Company Domain'] }.compact.uniq
    end

    def query_clearbit(domain)
      options = {
        query: {
          domain: domain,
          role: 'marketing'
        },
        basic_auth: {
          username: @secret_key,
          password: ''
        }
      }
      url = 'https://prospector.clearbit.com/v1/people/search'
      res = HTTParty.get(url, options)
      JSON.parse(res)
    end
  end
end
