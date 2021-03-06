module Mint
  class Formatter
    def format(node : Ast::Enum)
      name =
        format node.name

      items =
        node.options + node.comments

      body =
        list items

      comment =
        node.comment.try { |item| "#{format item}\n" }

      parameters =
        unless node.parameters.empty?
          "(#{format(node.parameters, ", ")})"
        end

      "#{comment}enum #{name}#{parameters} {\n#{indent(body)}\n}"
    end
  end
end
