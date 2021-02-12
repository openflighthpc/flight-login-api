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

require_relative 'app/errors'

configure do
  set :raise_errors, true
  set :show_exceptions, false
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

# Require the Content-Type and Accept headers to be set correctly
before method: :post do
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
end

post '/sign-in' do
  # Extract the username/password
  account = params.fetch('account', {})
  username = account['username']
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
  jwt_body = {
    username: passwd.name,
    name: passwd.gecos,
    iat: now,
    nbf: now,
    exp: (now + FlightWebAuth.config.token_expiry * 86400),
    iss: FlightWebAuth.config.issuer
  }
  payload = {
    username: passwd.name,
    name: passwd.gecos,
    authentication_token: JWT.encode(jwt_body, shared_secret, 'HS256')
  }

  # Return the payload
  status 201
  payload.to_json
end
