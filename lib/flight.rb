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

require 'active_support/string_inquirer'
require 'active_support/core_ext/object/blank'

module Flight
  # Injects the logger into the core module
  extend Console

  class << self
    def config
      # TODO: Log warnings within here
      @config ||= FlightLogin::Configuration.load
    end

    def root
      @root ||= if env.production? && ENV["flight_ROOT"].present?
        File.expand_path(ENV["flight_ROOT"])
      else
        File.expand_path('..', __dir__)
      end
    end

    def env
      @env ||= ActiveSupport::StringInquirer.new(
        ENV['RACK_ENV'].presence || "production"
      )
    end
  end
end
