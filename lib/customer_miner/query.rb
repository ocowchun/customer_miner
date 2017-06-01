require 'csv'
require 'json'
require 'clearbit'
require 'thread/pool'
require 'concurrent'

module CustomerMiner
  class Query
    VALID_ROLES = ['ceo', 'communications', 'consulting', 'customer_service',
      'education', 'engineering', 'finance', 'founder', 'health_professional',
      'human_resources', 'information_technology', 'legal', 'marketing',
      'operations', 'owner', 'president', 'product', 'public_relations',
      'real_estate', 'recruiting', 'research', 'sales']

    def initialize(file:, roles:, secret_key:)
      @file = file
      @secret_key = secret_key
      unless roles.kind_of? Array
        raise ArgumentError, "`roles` must be array"
      end
      roles.each do |role|
        unless VALID_ROLES.include?(role)
          raise ArgumentError, "Invalid role #{role}"
        end
      end
      @roles = roles
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
      Clearbit.key = @secret_key
      result = Concurrent::Array.new
      pool = Thread.pool(4)
      domains.each do |domain|
        pool.process do
          people = Clearbit::Prospector.search(domain: domain, roles: @roles)
          if people.size > 0
            result << { domain: domain, people: people }
          end
          puts "complete #{domain}"
        end
      end

      pool.shutdown
      puts "complete requests"
      result
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
