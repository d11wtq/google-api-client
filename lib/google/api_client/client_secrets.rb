# Copyright 2010 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'multi_json'


module Google
  class APIClient
    ##
    # Manages the persistence of client configuration data and secrets.
    class ClientSecrets
      def self.load(filename=nil)
        if filename && File.directory?(filename)
          search_path = File.expand_path(filename)
          filename = nil
        end
        while filename == nil
          search_path ||= File.expand_path('.')
          puts search_path
          if File.exist?(File.join(search_path, 'client_secrets.json'))
            filename = File.join(search_path, 'client_secrets.json')
          elsif search_path == '/' || search_path =~ /[a-zA-Z]:[\/\\]/
            raise ArgumentError,
              'No client_secrets.json filename supplied ' +
              'and/or could not be found in search path.'
          else
            search_path = File.expand_path(File.join(search_path, '..'))
          end
        end
        data = File.open(filename, 'r') { |file| APIClient.load_json(file.read) }
        return self.new(data)
      end

      def initialize(options={})
        # Client auth configuration
        @flow = options[:flow] || options.keys.first.to_s || 'web'
        fdata = options[@flow]
        @client_id = fdata[:client_id] || fdata["client_id"]
        @client_secret = fdata[:client_secret] || fdata["client_secret"]
        @redirect_uris = fdata[:redirect_uris] || fdata["redirect_uris"]
        @redirect_uris ||= [fdata[:redirect_uri]]
        @javascript_origins = (
          fdata[:javascript_origins] ||
          fdata["javascript_origins"]
        )
        @javascript_origins ||= [fdata[:javascript_origin]]
        @authorization_uri = fdata[:auth_uri] || fdata["auth_uri"]
        @authorization_uri ||= fdata[:authorization_uri]
        @token_credential_uri = fdata[:token_uri] || fdata["token_uri"]
        @token_credential_uri ||= fdata[:token_credential_uri]

        # Associated token info
        @access_token = fdata[:access_token] || fdata["access_token"]
        @refresh_token = fdata[:refresh_token] || fdata["refresh_token"]
        @id_token = fdata[:id_token] || fdata["id_token"]
        @expires_in = fdata[:expires_in] || fdata["expires_in"]
        @expires_at = fdata[:expires_at] || fdata["expires_at"]
        @issued_at = fdata[:issued_at] || fdata["issued_at"]
      end

      attr_reader(
        :flow, :client_id, :client_secret, :redirect_uris, :javascript_origins,
        :authorization_uri, :token_credential_uri, :access_token,
        :refresh_token, :id_token, :expires_in, :expires_at, :issued_at
      )

      def to_json
        return APIClient.dump_json({
          self.flow => ({
            'client_id' => self.client_id,
            'client_secret' => self.client_secret,
            'redirect_uris' => self.redirect_uris,
            'javascript_origins' => self.javascript_origins,
            'auth_uri' => self.authorization_uri,
            'token_uri' => self.token_credential_uri,
            'access_token' => self.access_token,
            'refresh_token' => self.refresh_token,
            'id_token' => self.id_token,
            'expires_in' => self.expires_in,
            'expires_at' => self.expires_at,
            'issued_at' => self.issued_at
          }).inject({}) do |accu, (k, v)|
            # Prunes empty values from JSON output.
            unless v == nil || (v.respond_to?(:empty?) && v.empty?)
              accu[k] = v
            end
            accu
          end
        })
      end
    end
  end
end
