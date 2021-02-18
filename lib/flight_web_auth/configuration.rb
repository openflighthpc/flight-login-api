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

module FlightWebAuth
  class Configuration
    autoload(:Loader, 'flight_web_auth/configuration/loader')

    PRODUCTION_PATH = 'etc/flight-web-auth.yaml'
    PATH_GENERATOR = ->(env) { "etc/flight-web-auth.#{env}.yaml" }

    class ConfigError < StandardError; end

    ATTRIBUTES = [
      {
        name: 'bind_address',
        env_var: true,
        default: 'tcp://127.0.0.1:922'
      },
      {
        name: 'cross_origin_domain',
        env_var: true,
        default: nil,
      },
      {
        name: 'pam_service',
        env_var: true,
        default: 'login'
      },
      {
        name: 'token_expiry',
        env_var: false,
        default: 7
      },
      {
        name: 'issuer',
        env_var: true,
        default: 'web-auth'
      },
      {
        name: 'shared_secret_path',
        env_var: true,
        default: ->(root) do
          root.join('etc/shared-secret.conf')
        end
      },
      {
        name: 'log_level',
        env_var: true,
        default: 'info'
      },
      {
        name: 'sso_cookie_name',
        env_var: true,
        default: 'flight_web_auth',
      },
    ]
    attr_accessor(*ATTRIBUTES.map { |a| a[:name] })

    def self.load(root)
      if ENV['RACK_ENV'] == 'production'
        Loader.new(root, root.join(PRODUCTION_PATH)).load
      else
        paths = [
          root.join(PATH_GENERATOR.call(ENV['RACK_ENV'])),
          root.join(PATH_GENERATOR.call("#{ENV['RACK_ENV']}.local")),
        ]
        Loader.new(root, paths).load
      end
    end

    def log_level=(level)
      @log_level = level
      FlightWebAuth.logger.send("#{@log_level}!")
    end

    def shared_secret
      @shared_secret ||= if File.exists?(shared_secret_path)
        File.read(shared_secret_path)
      else
        raise ConfigError, 'The shared_secret_path does not exist!'
      end
    end
  end
end
