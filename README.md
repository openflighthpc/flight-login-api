# Flight Login API

API server which authenticates user credentials using [pam](http://www.linux-pam.org/).

## Overview

Flight Login API provides a web interface for authenticating user credentials
using `PAM`. It will then issue a signed `Bearer Token` which can be used to
gain access to other `flight-web-suite` services.

## Installation

### Installing with the OpenFlight package repos

Flight Login API is available as part of the *Flight Web Suite*.  This is
the easiest method for installing Flight Login API and all its dependencies. 
It is documented in [the OpenFlight
Documentation](https://use.openflighthpc.org/installing-web-suite/install.html#installing-flight-web-suite).

### Manual Installation

#### Prerequisites

Flight Login API is developed and tested with Ruby version `2.7.1` and
`bundler` `2.1.4`.  Other versions may work but currently are not officially
supported.

#### Install Flight Login API

The following will install from source using `git`.  The `master` branch is
the current development version and may not be appropriate for a production
installation. Instead a tagged version should be checked out.

```
git clone https://github.com/alces-flight/flight-login-api.git
cd flight-login-api
git checkout <tag>
bundle config set --local with default
bundle config set --local without development
bundle install
```

The manual installation of Flight Login API comes preconfigured to run in
development mode.  If installing Flight Login API manually for production
usage you will want to follow the instructions to [set the environment
mode](docs/environment-modes.md) to `standalone`.

## Configuration

Flight Login API comes preconfigured to work out of the box without
further configuration.  However, it is likely that you will want to change its
`pam_service`, `bind_address` and `base_url`.

Please refer to the [configuration file](etc/login-api.yaml) for more details
and a full list of configuration options.

### Environment Modes

If Flight Login API has been installed manually for production usage you
will want to follow the instructions to [set the environment
mode](docs/environment-modes.md) to `standalone`.

## Operation

How do you use it?

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE](LICENSE) for details.

Copyright (C) 2021-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

flight-login is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
