require 'httparty'
require 'csv'
require 'json'
require 'typhoeus'

module CustomerMiner
  class Query
    def initialize(file:, secret_key:)
      @file = file
      @secret_key = secret_key
    end

    def perform
      domains = extract_domains
      puts "get #{domains.size} domain from csv #{@file}"
      puts "start request clearbit"
      query_clearbit(domains)
    end

    private

    def extract_domains
      reg = /^#.*/
      rows = CSV.read(@file, headers: true, skip_lines: reg)
      rows.map { |row| row['Clearbit Company Domain'] }.compact.uniq
    end

    def query_clearbit(domains)
      hydra = Typhoeus::Hydra.new(max_concurrency: 5)
      url = 'https://prospector.clearbit.com/v1/people/search'
      userpwd = "#{@secret_key}:"
      requests = domains.map do |domain|
        options = {
          userpwd: userpwd,
          params: {
            domain: domain,
            role: 'marketing'
          }
        }
        req = Typhoeus::Request.new(url, options)
        hydra.queue(req)
        req
      end
      hydra.run
      puts "complete requests"
      requests.select{ |req| req.response.success? }.map do |request|
        res_hash = JSON.parse(request.response.body)
        emails = res_hash.map { |person| person['email']}
        domain = request.options[:params][:domain]
        puts request.options[:params]
        puts "domain #{domain}"
        puts "#{emails.join(',')}"
      end
    end
  end
end
