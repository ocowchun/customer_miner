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
      res = query_clearbit(domains)
      build_csv(res)
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
      requests.select { |req| req.response.success? }.map do |request|
        res_hash = JSON.parse(request.response.body)
        domain = request.options[:params][:domain]
        { domain: domain, people: res_hash }
      end
    end

    def build_csv(res)
      rows = res.map do |item|
        domain = item[:domain]
        item[:people].map do |person|
          build_row(person, domain)
        end
      end
      headers = ['domain', 'fullName', 'title', 'role', 'seniority', 'email',
        'verified', 'phone'].join(',')
      file_content = [headers].concat(rows).join("\n")

      file_path = "#{Dir.pwd}/result.csv"
      File.open(file_path, 'w') do |file|
        file.write(file_content)
      end
      puts "save file in #{file_path}"
    end

    def build_row(person, domain)
      attrs = ['title', 'role', 'seniority', 'email', 'verified', 'phone']
      person_attrs = attrs.map { |attr| person[attr] }
      [domain, person['name']['fullName']].concat(person_attrs)
        .map { |str| str.to_s.gsub(',', ";") }
        .join(',')
    end
  end
end
