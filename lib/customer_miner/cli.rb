require 'thor'
require 'customer_miner/version'
require 'customer_miner/query'

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
    def query(args)
      unless args
        puts "plese speciy file name"
        return
      end

      file_name = "#{Dir.home}/.customer_miner"
      key = File.read(file_name)
      Query.new(file: args, secret_key:key).perform
    end

    def method_missing(file)
      query(file.to_s)
    end
  end
end
