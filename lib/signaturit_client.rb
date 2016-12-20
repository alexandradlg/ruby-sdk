# Load rest client
require 'rest_client'

# Load json
require 'json'

# Signaturit client class
class SignaturitClient

    # Initialize the object with the token and environment
    def initialize(token, production = false)
        base = production ? 'https://api.signaturit.com' : 'https://api.sandbox.signaturit.com'

        @client = RestClient::Resource.new base, :headers => { :Authorization => "Bearer #{token}", :user_agent => 'signaturit-ruby-sdk 1.0.2' }, :ssl_version => :TLSv1_2
    end

    # Get a concrete signature object
    #
    # Params:
    # +signature_id+:: The id of the signature object
    def get_signature(signature_id)
        request :get, "/v3/signatures/#{signature_id}.json"
    end

    # Get a list of signature objects
    #
    # Params:
    # +limit+:: Maximum number of results to return
    # +offset+:: Offset of results to skip
    # +conditions+:: Filter conditions
    def get_signatures(limit = 100, offset = 0, conditions = {})
        params = extract_query_params conditions

        params['limit']  = limit
        params['offset'] = offset

        request :get, "/v3/signatures.json", params
    end

    # Get the number of signature objects
    #
    # Params:
    # +conditions+:: Filter conditions
    def count_signatures(conditions = {})
        params = extract_query_params conditions

        request :get, "/v3/signatures/count.json", params
    end

    # Get the audit trail of concrete document
    #
    # Params:
    # +signature_id++:: The id of the signature object
    # +document_id++:: The id of the document object
    def download_audit_trail(signature_id, document_id)
        request :get, "/v3/signatures/#{signature_id}/documents/#{document_id}/download/audit_trail", {}, false
    end

    # Get the signed document
    #
    # Params:
    # +signature_id++:: The id of the signature object
    # +document_id++:: The id of the document object
    def download_signed_document(signature_id, document_id)
        request :get, "/v3/signatures/#{signature_id}/documents/#{document_id}/download/signed", {}, false
    end

    # Create a new Signature request
    #
    # Params:
    # +filepath+:: The pdf file to send or an array with multiple files.
    # +recipients+:: A string with an email, a hash like
    # {:name => "a name", :email => "me@domain.com", :phone => "34655123456"}
    # or an array of hashes.
    # +params+:: An array of parameters for the signature object
    def create_signature(filepath, recipients, params = {})
        params[:recipients] = {}

        [recipients].flatten.each_with_index do |recipient, index|
            # if only email is given, transform it to a object
            recipient = { email: recipient, name: recipient } if recipient.is_a? String

            # workaround for a bug in rest_client not dealing with objects inside an array
            if recipient[:require_signature_in_coordinates]
                recipient[:require_signature_in_coordinates] = array2hash recipient[:require_signature_in_coordinates]
            end

            params[:recipients][index] = recipient
        end

        params[:files] = [filepath].flatten.map do |filepath|
            File.new(filepath, 'rb')
        end

        params[:templates] = [params[:templates]].flatten if params[:templates]

        request :post, "/v3/signatures.json", params
    end

    # Cancel a signature request
    #
    # Params
    # +signature_id++:: The id of the signature object
    def cancel_signature(signature_id)
        request :patch, "/v3/signatures/#{signature_id}/cancel.json"
    end

    # Send a reminder for the given signature request document
    #
    # Param
    # +signature_id++:: The id of the signature object
    def send_signature_reminder(signature_id)
        request :post, "/v3/signatures/#{signature_id}/reminder.json"
    end

    # Get a concrete branding
    #
    # Params
    # +branding_id+:: The id of the branding object
    def get_branding(branding_id)
        request :get, "/v3/brandings/#{branding_id}.json"
    end

    # Get all account brandings
    def get_brandings
        request :get, "/v3/brandings.json"
    end

    # Create a new branding
    #
    # Params:
    # +params+:: An array of parameters for the branding object
    def create_branding(params)
        request :post, "/v3/brandings.json", params
    end

    # Update a existing branding
    #
    # Params:
    # +branding_id+:: Id of the branding to update
    # +params+:: Same params as method create_branding, see above
    def update_branding(branding_id, params)
        request :patch, "/v3/brandings/#{branding_id}.json", params
    end

    # Get a list of template objects
    #
    # Params:
    # +limit+:: Maximum number of results to return
    # +offset+:: Offset of results to skip
    def get_templates(limit = 100, offset = 0)
        params = { :limit => limit, :offset => offset }

        request :get, "/v3/templates.json", params
    end

    # Get all emails
    #
    # Params:
    # +limit+:: Maximum number of results to return
    # +offset+:: Offset of results to skip
    # +conditions+:: Query conditions
    def get_emails(limit = 100, offset = 0, conditions = {})
        params = extract_query_params conditions

        params['limit']  = limit
        params['offset'] = offset

        request :get, "/v3/emails.json", params
    end

    # Count all emails
    #
    # Params:
    # +conditions+:: Query conditions
    def count_emails(conditions = {})
        params = extract_query_params conditions

        request :get, "/v3/emails/count.json", params
    end

    # Get a single email
    #
    # Params:
    # +email_id+:: Id of email
    def get_email(email_id)
        request :get, "/v3/emails/#{email_id}.json"
    end

    # Create a new email
    #
    # Params:
    # +files+:: File or files to send with the email
    # +recipients+:: Recipients for the email
    # +subject+:: Email subject
    # +body+:: Email body
    # +params+:: Extra params
    def create_email(files, recipients, subject, body, params = {})
        params[:recipients] = {}

        [recipients].flatten.each_with_index do |recipient, index|
            params[:recipients][index] = recipient
        end

        params[:files] = [files].flatten.map do |filepath|
            File.new(filepath, 'rb')
        end

        params[:subject] = subject
        params[:body]    = body

        request :post, "/v3/emails.json", params
    end

    # Get the audit trail of concrete certificate
    #
    # Params:
    # +email_id++:: The id of the email object
    # +certificate_id++:: The id of the certificate object
    def download_email_audit_trail(email_id, certificate_id)
        request :get, "/v3/emails/#{email_id}/certificates/#{certificate_id}/download/audit_trail", {}, false
    end

    # Get all SMS
    #
    # Params:
    # +limit+:: Maximum number of results to return
    # +offset+:: Offset of results to skip
    # +conditions+:: Query conditions
    def get_sms(limit = 100, offset = 0, conditions = {})
        params = extract_query_params conditions

        params['limit']  = limit
        params['offset'] = offset

        request :get, "/v3/sms.json", params
    end

    # Count all SMS
    #
    # Params:
    # +conditions+:: Query conditions
    def count_sms(conditions = {})
        params = extract_query_params conditions

        request :get, "/v3/sms/count.json", params
    end

    # Get a single SMS
    #
    # Params:
    # +sms_id+:: Id of SMS
    def get_single_sms(sms_id)
        request :get, "/v3/sms/#{sms_id}.json"
    end

    # Create a new SMS
    #
    # Params:
    # +files+:: File or files to send with the SMS
    # +recipients+:: Recipients for the SMS
    # +body+:: SMS body
    # +params+:: Extra params
    def create_sms(files, recipients, body, params = {})
        params[:recipients] = {}

        [recipients].flatten.each_with_index do |recipient, index|
            params[:recipients][index] = recipient
        end

        params[:attachments] = [files].flatten.map do |filepath|
            File.new(filepath, 'rb')
        end

        params[:body] = body

        request :post, "/v3/sms.json", params
    end

    # Get the audit trail of concrete certificate
    #
    # Params:
    # +sms_id++:: The id of the SMS object
    # +certificate_id++:: The id of the certificate object
    def download_sms_audit_trail(sms_id, certificate_id)
        request :get, "/v3/sms/#{sms_id}/certificates/#{certificate_id}/download/audit_trail", {}, false
    end

    # PRIVATE METHODS FROM HERE
    private

    # convert array to hash recursively
    def array2hash(array)
        unless array.is_a?(Array)
            return array
        end

        Hash[
            array.map.with_index do |x, i|
                if x.is_a?(Array)
                    x = array2hash(x)
                end

                [i, x]
            end
        ]
    end

    # Parse query parameters
    def extract_query_params(conditions)
        params = {}

        conditions.each do |key, value|
            if key == 'ids'
                value = value.join(',')
            end

            params[key] = value
        end

        params
    end

    # Common request method
    def request(method, path, params = {}, to_json = true)
        case method
            when :get, :delete
                encoded = URI.encode_www_form(params)

                path = "#{path}?#{encoded}" if encoded.length > 0

                body = @client[path].send method

            else
                body = @client[path].send method, params
        end

        body = JSON.parse body if to_json

        body
    end

end
