module SupportAi
  # Turns a RubyLLM chat's messages into the JSON stored on Support::AiRun#transcript:
  # [{role:, content:, tool_calls: [{id:, name:, arguments:}], tool_call_id:}] in order.
  # Content is normalized to text (attachments by filename only) and truncated.
  module Transcript
    MAX_CONTENT = 20_000
    MARKER = "…[truncated]"

    module_function

    def build(messages)
      Array(messages).map { |message| entry(message) }
    end

    def entry(message)
      {
        role: message.role.to_s,
        content: text_for(message),
        tool_calls: Array(message.tool_calls&.values).map { |call| {id: call.id, name: call.name, arguments: call.arguments} },
        tool_call_id: message.tool_call_id
      }
    end

    def text_for(message)
      parts = [normalize(message.content)]
      attachments = message.respond_to?(:attachments) ? Array(message.attachments) : []
      attachments.each { |attachment| parts << "[#{attachment.type}: #{attachment.filename}]" }
      truncate(parts.compact_blank.join("\n"))
    end

    def normalize(content)
      case content
      when nil then ""
      when String then content
      when Hash, Array then JSON.generate(content)
      else
        content.respond_to?(:text) ? content.text.to_s : content.to_s
      end
    end

    def truncate(text)
      (text.length > MAX_CONTENT) ? text[0, MAX_CONTENT] + MARKER : text
    end
  end
end
