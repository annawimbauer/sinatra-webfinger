require 'sinatra/base'
require 'multi_json'

# To use:
#
#   require 'sinatra/webfinger'
#
# In classic style:
#
#   webfinger(config)
#
# In modular style:
#
#

module Sinatra

  module Webfinger
    def webfinger(config)
      get '/.well-known/webfinger' do
        halt 500 unless config
        halt 400 unless (resource = params[:resource]).present?
        halt 400 unless (uri = URI.parse(resource) rescue nil)
        halt 404 unless (uri.scheme.nil? or uri.scheme == "acct") # acct only

        # allow only email for now
        no_scheme = resource.sub /^acct:/, ''
        account = config[no_scheme] || config[resource]
        halt 404 unless account

        response = {
          subject: resource,
          properties: {},
          links: []
        }

        account.each do |field, value|
          uri = URI.parse(value) rescue nil
          if uri and uri.scheme and uri.scheme.starts_with?("http")
            response[:links] << {rel: field, href: value}
          else
            response[:properties][field] = value
          end
        end

        headers['Content-Type'] = 'application/jrd+json'
        headers['Access-Control-Allow-Origin'] = "*"

        MultiJson.encode response
      end
    end
  end

  register Webfinger
end