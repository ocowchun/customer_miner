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
  end
end
