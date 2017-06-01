require 'thor'
require 'customer_miner/version'
require 'customer_miner/query'
require 'concurrent'
require 'thread/pool'

module CustomerMiner
  class CLI< Thor
    map '--version' => :version

    desc 'version', 'Prints the cm version'
    def version
      puts "#{File.basename($0)} #{VERSION}"
    end

    desc 'set_key', 'Set secret API key. You can get it from https://dashboard.clearbit.com/api'
    option :key, required: true, banner: "your_secret_api_key"
    def set_key
      key = options[:key]
      file = "#{Dir.home}/.customer_miner"
      File.open(file, 'w') do |file|
        file.write(key)
      end
      File.chmod(0600, file)
      puts "Set secret API key successfully"
    end

    desc 'query', 'query customer data and generate csv file'
    option :file, required: true, banner: './your-clearbit.csv',
      desc: "CSV file export from Google Analytics"
    option :roles, required: false, banner: "marketing,operations",
      desc: "Roles you want to get. You can get available role in"\
      " http://support.clearbit.com/article/120-employment-role-and-seniority"
    def query
      file = options[:file]

      if options[:roles]
        roles = options[:roles].split(',')
      else
        roles = ['marketing']
      end

      secret_key_file_path = "#{Dir.home}/.customer_miner"
      secret_key = File.read(secret_key_file_path)
      Query.new(file: file, roles: roles, secret_key: secret_key).perform
    end
  end
end
