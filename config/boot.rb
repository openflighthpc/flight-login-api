# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2021-present Alces Flight Ltd.
#
# This file is part of Flight Login.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Login is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Login. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Login, please visit:
# https://github.com/openflighthpc/flight-login-api
#===============================================================================

# Converts the legacy FLIGHT_LOGIN_* env vars to the idiomatic format
# NOTE: Remove on the next major release
LEGACY_REGEX = /\AFLIGHT_LOGIN_(?<key>.*)\Z/
ENV.each do |env, value|
  match = LEGACY_REGEX.match(env)
  next unless match
  key = match.named_captures['key'].downcase
  ENV["flight_LOGIN_API_#{key}"] ||= value
end

# Bootstrap Bundler
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
require 'rubygems'
require 'bundler'
Bundler.setup(:default)

# Limited use of dotenv to set flight_ENVIRONMENT and RACK_ENV
require 'dotenv'
dot_files = [ '../.flight-environment' ].map do |file|
  File.expand_path(file, __dir__)
end
Dotenv.load(*dot_files)
ENV['RACK_ENV'] ||= 'development'

# Require the gems
if ENV['flight_ENVIRONMENT'] == 'development'
  Bundler.require(:default, :development)
else
  Bundler.require(:default)
end

# Add the lib directory onto the LOAD_PATH
lib = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# Commonly used libraries used within the application
require 'yaml'
require 'json'
require 'pathname'
require 'time'
require 'securerandom'

# Require the applciation
require 'flight'
require 'flight_login'
require_relative '../app'
