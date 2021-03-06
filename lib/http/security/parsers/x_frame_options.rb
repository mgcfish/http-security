require 'http/security/parsers/parser'

module HTTP
  module Security
    module Parsers
      class XFrameOptions < Parser
        # X-Frame-Options
        # Syntax:
        # X-Frame-Options = "DENY"
        #                    / "SAMEORIGIN"
        #                    / ( "ALLOW-FROM" RWS SERIALIZED-ORIGIN )
        #
        #          RWS             = 1*( SP / HTAB )
        #                        ; required whitespace
        # Only one can be present
        rule(:x_frame_options) do
          (
            deny        |
            same_origin |
            allow_from  |
            allow_all
          ).as(:directives)
        end
        root :x_frame_options

        directive_rule :deny, 'deny'
        directive_rule :same_origin, 'sameorigin'
        directive_rule :allow_all, 'allowall'

        rule(:allow_from) do
          stri("allow-from").as(:key) >> wsp.repeat(1) >>
          serialized_origin.as(:value)
        end

        #
        # URI
        #
        rule(:serialized_origin) do
          (
            scheme >> str(":") >> str("//") >> host_name >>
            (str(":") >> digits.as(:port)).maybe
          ).as(:uri)
        end
      end
    end
  end
end
