#!/bin/bash
set -ueo pipefail

# We don't want to add the embedded bin dir to the main PATH as this
# could mask issues in our binstub shebangs.
export EMBEDDED_BIN_DIR="/opt/cinc/embedded/bin"

# If we are on Mac our symlinks are located under /usr/local/bin
# otherwise they are under /usr/bin
if [[ -f /usr/bin/sw_vers ]]; then
  export USR_BIN_DIR="/usr/local/bin"
else
  export USR_BIN_DIR="/usr/bin"
fi

# Ensure the calling environment (disapproval look Bundler) does not
# infect our Ruby environment created by the `chef-client` cli.
for ruby_env_var in _ORIGINAL_GEM_PATH \
                    BUNDLE_BIN_PATH \
                    BUNDLE_GEMFILE \
                    GEM_HOME \
                    GEM_PATH \
                    GEM_ROOT \
                    RUBYLIB \
                    RUBYOPT \
                    RUBY_ENGINE \
                    RUBY_ROOT \
                    RUBY_VERSION \
                    BUNDLER_VERSION

do
  unset $ruby_env_var
done

# Exercise various packaged tools to validate binstub shebangs
echo ":ruby: Validating Ruby can run"
"$EMBEDDED_BIN_DIR/ruby" --version
echo ":gem: Validating RubyGems can run"
"$EMBEDDED_BIN_DIR/gem" --version
echo ":bundler: Checking Bundler version"
"$EMBEDDED_BIN_DIR/bundle" --version
echo ":carpentry_saw: Checking nokogiri version"
"$EMBEDDED_BIN_DIR/nokogiri" --version

"$EMBEDDED_BIN_DIR/ruby" -r openssl -e 'puts "Ruby can load OpenSSL"'

echo ":lock: Checking OpenSSL version"
"$EMBEDDED_BIN_DIR/openssl" version # ensure openssl command works

echo "Validating that OpenSSL does not error with SHA3"
"$EMBEDDED_BIN_DIR/openssl" sha3-512 < ./README.md

export PATH=$EMBEDDED_BIN_DIR:$PATH
if [ "$OMNIBUS_FIPS_MODE" = "true" ]
then
  export OPENSSL_FIPS=1
fi


if [ "$OMNIBUS_FIPS_MODE" = "true" ]
then

  echo "the ruby we _expect_ to be using"
  echo "--------------------------------"
  echo "Checking $EMBEDDED_BIN_DIR/ruby"
  sum $EMBEDDED_BIN_DIR/ruby
  "$EMBEDDED_BIN_DIR/ruby" -v -e "require 'openssl'; puts OpenSSL::OPENSSL_VERSION_NUMBER.to_s(16); puts OpenSSL::OPENSSL_LIBRARY_VERSION; OpenSSL.fips_mode = 1; puts 'OpenSSL FIPS validated for ' + RUBY_VERSION"

  echo "FIPS is enabled, checking FIPS mode"
  ls -l /opt/cinc/embedded/ssl/fipsmodule.cnf

  echo "Listing openssl providers"
  "$EMBEDDED_BIN_DIR/openssl" list -providers # fips should be a provider here

  echo ":closed_lock_with_key: Checking FIPS mode"
  "$EMBEDDED_BIN_DIR/openssl" md5 < ./README.md

  if [ $? -eq 0 ]
  then
    ret_code=$?
    echo "openssl executable still allows md5"
    # exit $?
  fi

else
  echo "FIPS is not enabled, skipping FIPS mode functionality test"
fi
