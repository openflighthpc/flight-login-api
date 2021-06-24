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
#==============================================================================

module FlightLogin
  Auth = Struct.new(:encoded) do
    def self.build(cookie, header)
      if cookie
        new(cookie)
      elsif match = /\ABearer (.*)\Z/.match(header || '')
        new(match[1])
      else
        new('')
      end
    end

    def valid?
      !decoded[:invalid]
    end

    def forbidden?
      decoded[:forbidden]
    end

    def username
      decoded['username']
    end

    def token
      decoded
    end

    private

    def decoded
      @decoded ||= begin
        JWT.decode(
          encoded,
          Flight.config.shared_secret,
          true,
          { algorithm: 'HS256' },
        ).first.tap do |hash|
          unless hash['username']
            hash[:invalid] = true
            hash[:forbidden] = true
          end
        end
      rescue JWT::VerificationError
        { invalid: true, forbidden: true }
      rescue JWT::DecodeError
        { invalid: true }
      end
    end
  end
end
