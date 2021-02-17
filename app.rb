# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2021-present Alces Flight Ltd.
#
# This file is part of Flight Web Auth.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Web Auth is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Web Auth. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Web Auth, please visit:
# https://github.com/openflighthpc/flight-web-auth-api
#===============================================================================

require 'sinatra'
require 'sinatra/cross_origin'

require_relative 'app/errors'

# This regular expression is used to split the levels of a domain.
# The top level domain can be any string without a period or
# **.**, ***.** style TLDs like co.uk or com.au
#
# www.example.co.uk gives:
# $& => example.co.uk
#
# example.com gives:
# $& => example.com
#
# lots.of.subdomains.example.local gives:
# $& => example.local
DOMAIN_REGEXP = /[^.]*\.([^.]*|..\...|...\...)$/

configure do
  set :raise_errors, true
  set :show_exceptions, false

  enable :cross_origin if FlightWebAuth.config.cross_origin_domain
end

not_found do
  { errors: ['Not Found'] }.to_json
end

# Converts HttpError objects into their JSON representation. Each object already
# sets the response code
error(HttpError) do
  e = env['sinatra.error']
  level = (e.is_a?(UnexpectedError) ? :error : :debug)
  LOGGER.send level, e.full_message
  status e.http_status
  { errors: [e.message.chomp] }.to_json
end

# Catches all other errors and returns a generic Internal Server Error
error(StandardError) do
  LOGGER.error env['sinatra.error'].full_message
  status 500
  { errors: ['An unexpected error has occurred!'] }.to_json
end

class PamAuth
  def self.valid?(username, password)
    Rpam.auth(username, password, service: FlightWebAuth.config.pam_service)
  end
end

before do
  if FlightWebAuth.config.cross_origin_domain
    origin = FlightWebAuth.config.cross_origin_domain
    if origin.to_s == 'any'
      origin = request.env['HTTP_X_ORIGIN'] || request.env['HTTP_ORIGIN']
    end
    response.headers['Access-Control-Allow-Origin'] = origin
    response.headers["Access-Control-Allow-Credentials"] = "true"
  end
end

# Require the Content-Type and Accept headers to be set correctly
before method: :post do
  # Not sure why we need this check, but we do.
  next if env['REQUEST_METHOD'] == 'OPTIONS'

  unless request.content_type == 'application/json'
    raise UnsupportedMediaType, 'Content-Type must be application/json'
  end
  unless request.accept?('application/json')
    raise NotAcceptable, 'Accept must be application/json'
  end
end

use Rack::Parser, parsers: {
  'application/json' => ->(body) { JSON.parse(body) }
}

helpers do
  def shared_secret
    @shared_secret ||= File.read(FlightWebAuth.config.shared_secret_path)
  end

  def set_sso_cookie(auth_token, expires)
    domain = 
      if request.host == 'localhost'
        'localhost'
      elsif (request.host !~ /^[\d.]+$/) && (request.host =~ DOMAIN_REGEXP)
        ".#{$&}"
      end

    response.set_cookie(
      FlightWebAuth.app.config.sso_cookie_name,
      value: auth_token,
      domain: domain,
      path: '/',
      expires: Time.at(expires),
      secure: request.scheme == 'https',
      http_only: true,
      same_site: :strict,
    )
  end
end

if FlightWebAuth.config.cross_origin_domain
  options "*" do
    response.headers["Allow"] = "POST, OPTIONS"
    response.headers["Access-Control-Allow-Methods"] = "POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept"
    status 200
    ''
  end
end

post '/sign-in' do
  # Extract the username/password
  account = params.fetch('account', {})
  username = account['login']
  password = account['password']

  # Ensure they have been provided
  if username.nil?
    raise UnprocessableEntity, 'The username has not been provided'
  end
  if password.nil?
    raise UnprocessableEntity, 'The password has not been provided'
  end

  # Ensures the username/password is valid
  unless PamAuth.valid?(username, password)
    raise Forbidden, 'you do not have permission to access this service'
  end

  # Generates the responds
  passwd = Etc.getpwnam(username)
  now = Time.now.to_i
  expires = now + FlightWebAuth.config.token_expiry * 86400
  gecos_name = (passwd.gecos || "").split(',').first
  jwt_body = {
    username: passwd.name,
    name: gecos_name,
    iat: now,
    nbf: now,
    exp: expires,
    iss: FlightWebAuth.config.issuer
  }
  auth_token = JWT.encode(jwt_body, shared_secret, 'HS256')
  payload = {
    user: {
      username: passwd.name,
      name: gecos_name,
      authentication_token: auth_token,
    }
  }
  set_sso_cookie(auth_token, expires)

  # Return the payload
  status 201
  payload.to_json
end
