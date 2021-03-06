require File.expand_path('../ssi_processor', __FILE__)
require 'rest_client'
require 'logger'

module Rack
  class SSI
    
    def initialize(app, options = {})
      @app = app
      @logging = options[:logging] == :on
      @locations = options[:locations] || {}
      @predicate = options[:when] || lambda {|_| true}
    end

    def call(env)
      status, headers, body = @app.call(env)
      unprocessed = [status, headers, body]
      
      return unprocessed unless @predicate.call(env)
      return unprocessed unless headers["Content-Type"] && headers["Content-Type"].include?("text/html")
      return unprocessed unless status == 200
      
      ssi = Rack::SSIProcessor.new
      ssi.locations = @locations
      ssi.logger = logger(env) if @logging
      new_body = ssi.process(body)      
      headers["Content-Length"] = (new_body.reduce(0) {|sum, part| sum + part.bytesize}).to_s

      [status, headers, new_body]
    end
    
    private
    def logger(env)
      if defined?(Rails)
        return Rails.logger
      end
      env['rack.logger']
    end

  end
end
