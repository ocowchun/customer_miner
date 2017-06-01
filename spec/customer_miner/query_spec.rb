require 'customer_miner/query'
require 'webmock/rspec'
require 'json'
require 'clearbit'

describe 'Query' do
  describe '#perform' do
    let(:domains) do
      ['codementor.io', 'twitter.com']
    end
    let(:mock_rows) do
      domains.map do |domain|
        { 'Clearbit Company Domain' => domain }
      end
    end
    let(:file) { 'the-file' }
    let(:secret_key) { 'the-secret_key' }
    let(:roles) { ['product'] }
    let(:query) do
      CustomerMiner::Query.new(file: file, roles: roles, secret_key: secret_key)
    end
    before :each do
      allow(CSV).to receive(:read).and_return(mock_rows)
      allow(File).to receive(:open)
      mock_people = [{ 'name' => { 'fullName' => 'user-fullname' } }]
      allow(Clearbit::Prospector).to receive(:search).and_return(mock_people)
    end

    it "should request clearbit" do
      query.perform

      domains.each do |domain|
        expect(Clearbit::Prospector).to have_received(:search).with(domain: domain, roles: roles)
      end
    end

    it "should build csv file" do
      query.perform

      file_path = "#{Dir.pwd}/result.csv"
      expect(File).to have_received(:open).with(file_path, 'w')
    end
  end
end
