# encoding: utf-8

require "smart_colored/extend"

module Messages
  STATES_TO_PREFIXES = {
    :header => "  ",
    :item   => "    "
  }

  # print messages only by one thread at a time
  # puts is not atomic and might mangle outputs
  # (trailing newlines) from threads
  @log_lock = Mutex.new

  class << self
    def header(message)
      @log_lock.synchronize { puts message.bold }

      in_state(:header) { yield }
    end

    def item(message)
      @log_lock.synchronize { puts "  * #{message}..." }

      in_state(:item) { yield }
    end

    def info(message)
      log $stdout, message
    end

    def warning(message)
      log $stderr, "WARNING: #{message}".yellow
    end

    def error(message)
      log $stderr, "ERROR: #{message}".red
    end

    private

    def in_state(state)
      saved_state = @state
      @state = state
      yield
      @state = saved_state
    end

    def log(stream, message)
      prefix = STATES_TO_PREFIXES[@state] || ""

      @log_lock.synchronize { stream.puts "#{prefix}#{message}" }
    end
  end
end
