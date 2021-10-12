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

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'activesupport', require: 'active_support'
gem 'dotenv'
gem 'console'
gem 'rake'
gem 'flight_configuration', github: 'openflighthpc/flight_configuration', tag: '0.6.0'
gem 'rack-parser', :require => 'rack/parser'
gem 'rpam-ruby19', require: 'rpam'
gem 'puma'
gem 'sinatra'
gem 'sinatra-cross_origin'
gem 'jwt'

group :development, :test do
  gem 'pry'
  gem 'pry-byebug'
end

group :test do
  gem 'rack-test'
  gem 'rspec'
  gem 'rspec-collection_matchers'
end
