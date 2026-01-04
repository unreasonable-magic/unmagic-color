# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass
RSpec.describe("README.md") do
  let(:readme_path) { File.join(__dir__, "..", "README.md") }
  let(:readme_content) { File.read(readme_path) }

  # Extract all Ruby code blocks from the README
  let(:ruby_code_blocks) do
    readme_content.scan(/```ruby\n(.*?)```/m).flatten
  end

  describe "Ruby code examples" do
    it "extracts code blocks from README" do
      expect(ruby_code_blocks).not_to(be_empty)
    end

    it "all have valid Ruby syntax" do
      ruby_code_blocks.each_with_index do |code_block, index|
        expect do
          RubyVM::InstructionSequence.compile(code_block)
        end.not_to(raise_error, "Syntax error in code block ##{index + 1}:\n#{code_block}")
      end
    end

    it "executes code and validates assertions" do
      # Suppress all stdout during execution
      require "stringio"
      original_stdout = $stdout

      ruby_code_blocks.each_with_index do |code_block, block_index|
        lines = code_block.lines
        context_lines = []

        lines.each_with_index do |line, line_index|
          # Check if line has an assertion comment
          if line =~ /(.+?)\s*#\s*=>\s*(.+)/
            code_part = Regexp.last_match(1).strip
            expected_value = Regexp.last_match(2).strip

            # Skip approximate values (marked with ~)
            if expected_value.start_with?("~")
              context_lines << code_part
              next
            end

            # Build the full context including this line
            full_code = (context_lines + [code_part]).join("\n")

            # Execute and capture result
            # For puts statements, capture stdout instead of return value
            result = begin
              $stdout = StringIO.new # rubocop:disable RSpec/ExpectOutput

              if code_part.strip.start_with?("puts ")
                # Capture stdout for puts statements
                eval(full_code) # rubocop:disable Security/Eval
                output = $stdout.string.strip.lines.last.strip
                # Parse the output as the appropriate Ruby type
                # For strings like "#FF5733", eval them as string literals
                if output.start_with?("#")
                  output
                else
                  eval(output) # rubocop:disable Security/Eval
                end
              else
                eval(full_code) # rubocop:disable Security/Eval
              end
            rescue StandardError => e
              raise "Error executing code block ##{block_index + 1}, line #{line_index + 1}:\n#{full_code}\n\nError: #{e.message}"
            end

            # Compare result with expected value
            # Parse expected value as Ruby code to handle strings, numbers, arrays, etc.
            expected = eval(expected_value) # rubocop:disable Security/Eval

            expect(result).to(
              eq(expected),
              "Assertion failed in code block ##{block_index + 1}, line #{line_index + 1}:\n" \
                "Code: #{code_part}\n" \
                "Expected: #{expected.inspect}\n" \
                "Got: #{result.inspect}",
            )

            # Add this line to context for subsequent assertions
            context_lines << code_part
          elsif line.strip.start_with?("#") || line.strip.empty?
            # Skip comments and empty lines for context
            next
          else
            # Add non-assertion code to context
            context_lines << line.rstrip
          end
        end
      end
    ensure
      $stdout = original_stdout # rubocop:disable RSpec/ExpectOutput
    end
  end
end
# rubocop:enable RSpec/DescribeClass
