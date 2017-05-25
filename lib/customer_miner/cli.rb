require 'thor'
require 'customer_miner/version'

module CustomerMiner
  class CLI< Thor
    map '--version' => :version

    desc 'version', 'Prints the cm version'
    def version
      puts "#{File.basename($0)} #{VERSION}"
    end

  end
end
