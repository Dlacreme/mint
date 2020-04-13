module Mint
  module LS
    # This is the class that handles the "textDocument/hover" request.
    class Hover < LSP::RequestMessage
      property params : LSP::TextDocumentPositionParams

      # Fallback handler for nil, obviously it should not happen.
      def hover(node : Nil, workspace) : Array(String | Nil)
        ["SHOULD NOT HAPPEN"] of String | Nil
      end

      # Fallback handler for nodes that does not have a handler yet.
      def hover(node : Ast::Node, workspace) : Array(String | Nil)
        type =
          workspace.type_checker.cache[node]?.try do |value|
            "TYPE: #{value.to_mint}"
          end

        [
          "MISSING HOVER INFO: #{node.class}\n",
          type,
        ]
      end

      def execute(server)
        # Get the URI of the text document
        uri =
          URI.parse(params.text_document.uri)

        # Get the workspace associated with the text document
        # this could take a while because the workspace parses
        # and type checks all of it's source files.
        workspace =
          Workspace[uri.path.to_s]

        contents =
          if error = workspace.error
            # If the workspace has an error we cannot really
            # provide and hover information, so we just provide
            # the error istead.
            [
              "Cannot provide hover data because of an error:\n",
              error.to_terminal.to_s,
            ]
          else
            # We get the stack of nodes under the cursor
            stack =
              server.nodes_at_cursor(params)

            # TODO: Print the stack for debugging purposes.
            server.debug_stack(stack)

            node, parent =
              stack

            case node
            when Ast::Variable
              # If the first node under the cursor is a variable then
              # get the associated nodes information and hover that
              # otherwise get the hover information of the parent.
              lookup =
                workspace.type_checker.variables[node]?

              if lookup
                case item = lookup[0]
                when Ast::Node
                  hover(item, workspace)
                else
                  [item.to_s]
                end
              else
                hover(parent, workspace)
              end
            else
              hover(node, workspace)
            end
          end

        # Send the response.
        server.send({
          jsonrpc: "2.0",
          id:      id,
          result:  {
            contents: contents.compact,
          },
        })
      end
    end
  end
end
