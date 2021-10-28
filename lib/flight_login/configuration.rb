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

require 'flight_configuration'

module FlightLogin
  class ConfigError < StandardError; end

  class Configuration
    include FlightConfiguration::DSL
    include FlightConfiguration::RichActiveValidationErrorMessage

    application_name 'login-api'

    PRODUCTION_PATH = 'etc/flight-login.yaml'
    PATH_GENERATOR = ->(env) { "etc/flight-login.#{env}.yaml" }

    RC = Dotenv.parse(File.join(Flight.root, 'etc/web-suite.rc'))

    [
      {
        name: 'bind_address',
        env_var: true,
        default: 'tcp://127.0.0.1:922'
      },
      {
        name: 'cross_origin_domain',
        env_var: true,
        default: nil,
        required: false
      },
      {
        name: 'pam_service',
        env_var: true,
        default: 'sshd'
      },
      {
        name: 'token_expiry',
        env_var: true,
        default: 7
      },
      {
        name: 'issuer',
        env_var: true,
        default: 'login-api'
      },
      {
        name: 'shared_secret_path',
        env_var: true,
        default: 'etc/shared-secret.conf',
        transform: relative_to(Flight.root)
      },
      {
        name: 'log_level',
        env_var: true,
        default: 'info'
      },
      {
        name: 'sso_cookie_name',
        env_var: true,
        default: 'flight_login',
      },
      {
        name: 'sso_cookie_domain',
        env_var: false,
        default: RC["flight_WEB_SUITE_domain"]
      }
    ].each do |attr|
      attribute(attr[:name], **attr)
    end

    attribute :log_path, required: false,
          default: '/dev/stdout',
          transform: ->(path) do
            if path
              relative_to(root_path).call(path).tap do |full_path|
                FileUtils.mkdir_p File.dirname(full_path)
              end
            else
              $stderr
            end
          end

    def validate!
      super
      shared_secret
    end

    def shared_secret
      @shared_secret ||= if File.exists?(shared_secret_path)
        File.read(shared_secret_path)
      else
        raise ConfigError, "The shared_secret_path does not exist! #{shared_secret_path}"
      end
    end
  end
end
