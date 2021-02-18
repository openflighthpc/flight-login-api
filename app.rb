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
before do
  next if env['REQUEST_METHOD'] == 'OPTIONS'

  unless request.accept?('application/json')
    raise NotAcceptable, 'Accept must be application/json'
  end

  next if %w(GET DELETE).include? env['REQUEST_METHOD']
  unless request.content_type == 'application/json'
    raise UnsupportedMediaType, 'Content-Type must be application/json'
  end
end

use Rack::Parser, parsers: {
  'application/json' => ->(body) { JSON.parse(body) }
}

helpers do
  def shared_secret
    FlightWebAuth.config.shared_secret
  end

  def set_sso_cookie(auth_token)
    response.set_cookie(
      FlightWebAuth.app.config.sso_cookie_name,
      domain: FlightWebAuth.app.sso_cookie_domain,
      expires: Time.at(expiration),
      http_only: true,
      path: '/',
      same_site: :strict,
      secure: request.scheme == 'https',
      value: auth_token,
    )
  end

  def delete_sso_cookie
    response.delete_cookie(
      FlightWebAuth.app.config.sso_cookie_name,
      domain: sso_cookie_domain,
      http_only: true,
      path: '/',
      same_site: :strict,
      secure: request.scheme == 'https',
    )
  end

  def timestamp_now
    @_timestamp_now ||= Time.now.to_i
  end

  def expiration
    timestamp_now + FlightWebAuth.config.token_expiry * 86400
  end

  def create_auth_token(passwd, gecos_name)
    jwt_body = {
      username: passwd.name,
      name: gecos_name,
      iat: timestamp_now,
      nbf: timestamp_now,
      exp: expiration,
      iss: FlightWebAuth.config.issuer
    }
    JWT.encode(jwt_body, shared_secret, 'HS256')
  end

  def payload(passwd, gecos_name, auth_token)
    {
      user: {
        username: passwd.name,
        name: gecos_name,
        authentication_token: auth_token,
      }
    }
  end
end

if FlightWebAuth.config.cross_origin_domain
  options "*" do
    response.headers["Allow"] = "GET, DELETE, POST, OPTIONS"
    response.headers["Access-Control-Allow-Methods"] = "GET, DELETE, POST, OPTIONS"
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
  gecos_name = (passwd.gecos || "").split(',').first
  auth_token = create_auth_token(passwd, gecos_name)
  set_sso_cookie(auth_token)

  status 201
  payload(passwd, gecos_name, auth_token).to_json
end

get '/session' do
  auth = FlightWebAuth::Auth.build(
    request.cookies[FlightWebAuth.app.config.sso_cookie_name], env['HTTP_AUTHORIZATION']
  )

  unless auth.valid?
    raise Forbidden, 'you do not have permission to access this service'
  end

  passwd = Etc.getpwnam(auth.username)
  gecos_name = (passwd.gecos || "").split(',').first
  auth_token = JWT.encode(auth.token, shared_secret, 'HS256')
  set_sso_cookie(auth_token)
  status 200
  payload(passwd, gecos_name, auth_token).to_json
end

delete '/sign-out' do
  delete_sso_cookie
  status 204
end
