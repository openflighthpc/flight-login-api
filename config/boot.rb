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

ENV['RACK_ENV'] ||= 'development'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'rubygems'
require 'bundler'
require 'yaml'
require 'json'
require 'pathname'
require 'time'
require 'securerandom'

if ENV['RACK_ENV'] == 'development'
  Bundler.require(:default, :development)
else
  Bundler.require(:default)
end

# Shared activesupport libraries
require 'active_support/core_ext/hash/keys'

lib = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'flight_login'

# Ensure the sso_cookie_domain is set
unless FlightLogin.app.config.sso_cookie_domain
  FlightLogin.logger.fatal "The sso_cookie_domain configuration has not been set!"
  exit 1
end

# Ensure a shared secret exists
unless File.exists? FlightLogin.app.config.shared_secret_path
  FlightLogin.logger.warn "Generating a shared secret"
  File.write FlightLogin.config.shared_secret_path, SecureRandom.alphanumeric(40)
  FileUtils.chmod 0400, FlightLogin.config.shared_secret_path
end

require_relative '../app'
