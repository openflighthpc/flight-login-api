## Environment Modes

Flight Login API has three supported environment modes in which it can
operate: `integrated`, `standalone`, and `development`.

* `integrated`:  Used when installed via the OpenFlight repos.
* `standalone`:  Used for a manual installation intended for production.
* `development`: Used for a manual installation intended for development. 


### Integrated environment mode

This mode is automatically selected when Flight Login API is installed
from the OpenFlight repos.  The configuration file will be loaded from
`${flight_ROOT}/etc/login-api.yaml`.  Any relative paths in the
configuration file are expanded from `${flight_ROOT}`.


### Standalone environment mode

This mode is to be used for a manual installation intended for production
usage.  The configuration file is loaded from a path relative to the Flight
Login API installation directory.  Any relative paths in the
configuration file are expanded from the Flight Login API installation
directory.

For example, if the git repo was cloned to, say, `/opt/flight-login-api`,
the configuration file would be loaded from
`/opt/flight-login-api/etc/login-api.yaml` and, the relative path for the
`shared_secret_path` (`etc/shared-secret.conf`) would be expanded to
`/opt/flight-login-api/etc/shared-secret.conf`.

There are three mechanisms by which standalone mode can be activated, any of
which is sufficient.

* Create the file `.flight-environment` containing the line
  `flight_ENVIRONMENT=standalone`.
  ```
  echo flight_ENVIRONMENT=standalone > .flight-enviornment
  ```
* Export the environment variable `flight_ENVIRONMENT` set to `standalone`.
  ```
  export flight_ENVIRONMENT=standalone
  ```
* Ensure that the `.flight-environment` file doesn't exist and that the
  `flight_ENVIRONMENT` variable isn't set.
  ```
  rm .flight-environment
  ```

The file `.flight-environment` needs to be created at the root of the API code
base.  So if the git repo was cloned to, say, `/opt/flight-login-api`, the
flight environment file would be created at
`/opt/flight-login-api/.flight-environment`.

### Development environment mode

This mode is to be used for a manual installation intended for development of
Flight Login API.  The configuration file is loaded from a path relative to the
Flight Login API installation directory.  Any relative paths in the
configuration file are expanded from the Flight Login API installation
directory.

So if the git repo was cloned to, say, `/opt/flight-login-api`, the
configuration file would be loaded from
`/opt/flight-login-api/etc/login-api.yaml` and any relative paths
expanded from `/opt/flight-login-api`.  E.g., by default the
`shared_secret_path` (`etc/shared-secret.conf`) would be expanded to
`/opt/flight-login-api/etc/shared-secret.conf`.

There are two mechanisms by which development mode can be activated, either
of which is sufficient.

* Create the file `.flight-envionment` containing the line
  `flight_ENVIRONMENT=development`.
  ```
  echo flight_ENVIRONMENT=development > .flight-environment
  ```
* Export the environment variable `flight_ENVIRONMENT` set to `development`.
  ```
  export flight_ENVIRONMENT=development
  ```
