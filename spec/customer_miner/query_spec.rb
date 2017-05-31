require 'customer_miner/query'
require 'webmock/rspec'
require 'json'

describe 'Query' do
  let(:domains) do
    ['codementor.io', 'twitter.com']
  end
  let(:mock_rows) do
    domains.map do |domain|
      { 'Clearbit Company Domain' => domain}
    end
  end
  let(:file) { 'the-file' }
  let(:secret_key) { 'the-secret_key' }
  let(:query) do
    CustomerMiner::Query.new(file: file, secret_key: secret_key)
  end
  before :each do
    allow(CSV).to receive(:read).and_return(mock_rows)
    allow(File).to receive(:open)
    reg = /https:\/\/prospector.clearbit.com\/v1\/people\/search?.*/
    stub_request(:get, reg).to_return do |request|
      body = [{'name' => { 'fullName' => 'user-fullname'}}].to_json
      { body: body }
    end
  end

  it "should request clearbit" do
    query.perform

    domains.each do |domain|
      url = "https://prospector.clearbit.com/v1/people/search?domain=#{domain}&role=marketing"
      expect(WebMock).to have_requested(:get, url)
    end
  end

  it "should build csv file" do
    query.perform

    file_path = "#{Dir.pwd}/result.csv"
    expect(File).to have_received(:open).with(file_path, 'w')
  end
end