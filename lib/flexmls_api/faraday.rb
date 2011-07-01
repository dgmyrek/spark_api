module FlexmlsApi
  module FaradayExt
    #=Flexmls API Faraday middleware
    # HTTP Response after filter to package api responses and bubble up basic api errors.
    class FlexmlsMiddleware < Faraday::Response::ParseJson
      
      # Handles pretty much all the api response parsing and error handling.  All responses that
      # indicate a failure will raise a FlexmlsApi::ClientError exception
      def on_complete(finished_env)
        body = parse(finished_env[:body])
        FlexmlsApi.logger.debug("Response Body: #{body.inspect}")
        unless body.is_a?(Hash) && body.key?("D")
          raise InvalidResponse, "The server response could not be understood"
        end
        response = ApiResponse.new body
        case finished_env[:status]
        when 400, 409
          raise BadResourceRequest, {:message => response.message, :code => response.code, :status => finished_env[:status]}
        when 401
          # Handle the WWW-Authenticate Response Header Field if present. This can be returned by 
          # OAuth2 implementations and wouldn't hurt to log.
          auth_header_error = finished_env[:request_headers]["WWW-Authenticate"]
          FlexmlsApi.logger.warn("Authentication error #{auth_header_error}") unless auth_header_error.nil?
          raise PermissionDenied, {:message => response.message, :code => response.code, :status => finished_env[:status]}
        when 404
          raise NotFound, {:message => response.message, :code => response.code, :status => finished_env[:status]}
        when 405
    raise NotAllowed, {:message => response.message, :code => response.code, :status => finished_env[:status]}
        when 500
          raise ClientError, {:message => response.message, :code => response.code, :status => finished_env[:status]}
        when 200..299
          FlexmlsApi.logger.debug("Success!")
        else 
          raise ClientError, {:message => response.message, :code => response.code, :status => finished_env[:status]}
        end
        finished_env[:body] = response
      end
      
      def initialize(app)
        super(app)
      end
      
    end

  end
end
