require File.expand_path("../spec_helper.rb", File.dirname(__FILE__))
require File.expand_path("../../lib/gwooks/app.rb", File.dirname(__FILE__))
require "rack/test"

Gwooks::App.instance_eval do
  set :environment, :test
end

describe Gwooks::App do

  include Rack::Test::Methods

  def app
    Gwooks::App
  end

  describe :use_webhook do
    it "sets settings.webhook" do 
      Gwooks::App.should_receive(:set).with(:webhook, "foo")
      Gwooks::App.use_webhook("foo")
    end
  end

  describe "POST /" do
    it "raises if settings.webhook is not set" do
      Gwooks::App.stub(:webhook).and_return(nil) 
      expect {
        post "/"
      }.to raise_error(StandardError, /No webhook specified/)
    end

    it "invokes webhook.call() passing payload" do
      webhook = Proc.new {}
      Gwooks::App.stub(:webhook).and_return(webhook)
      payload = "\{\}"
      webhook.should_receive(:call).with(payload)
      post "/", :payload => payload
    end
  end

end
