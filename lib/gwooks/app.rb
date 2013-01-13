require "sinatra/base"

module Gwooks
  class App < Sinatra::Base

    post "/" do
      raise "No webhook specified." if settings.webhook.nil?
      settings.webhook.call(params[:payload])
    end

    def self.use_webhook(hook)
      set :webhook, hook
    end

  end
end
