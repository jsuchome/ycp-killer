# encoding: utf-8

require_relative "../messages"

module Commands
  class Command
    protected

    def action(message)
      Messages.item message do
        begin
          yield
        rescue Exception => e
          Messages.error "#{message} failed."
          raise
        end
      end
    end

    def file_action(message, phase, mod, file)
      action "#{message} #{file}" do
        begin
          yield
          @counts[:ok] += 1
        rescue Exception => e
          Messages.error "#{message} #{file} failed."
          handle_exception(e, phase, mod, file)
          @counts["error_#{phase}".to_sym] += 1
        end
      end
    end

    def reset_counts(mod)
      @counts = {
        :ok          => 0,
        :excluded    => mod.excluded.size,
        :error_ybc   => 0,
        :error_y2r   => 0,
        :error_ruby  => 0,
        :error_other => 0
      }
    end

    def handle_exception(e, phase, mod, file)
      raise if e.is_a? Interrupt

      if ! e.is_a? Cheetah::ExecutionFailed
        phase = :other
      end
      log_error(mod, file, e)
    end

    def log_error(mod, file, e)
      File.open(ERROR_FILE, "a") do |f|
        header = "[#{mod.name}] #{file}"
        f.puts header
        f.puts "-" * header.size
        f.puts
        if e.is_a?(Cheetah::ExecutionFailed)
          f.puts e.stderr
        else
          f.puts e.message
          e.backtrace.each { |l| f.puts l }
        end
        f.puts
      end
    end

    # A wrapper for saving and restoring environment after changes
    #
    # Example:
    #
    #   save_env do
    #     ENV["foo"] = bar
    #     foo()
    #   end
    #
    #   # here is the original ENV restored
    def save_env
      begin
        # ENV isn't a Hash, but a weird Hash-like object. Calling #to_hash on it
        # will copy its items into a newly created Hash instance, which then can
        # be fed into #replace. This approach ensures that any modifications of
        # ENV in the passed block won't affect the stored value.
        env_old = ENV.to_hash
        yield
      ensure
        ENV.replace env_old
      end
    end
  end
end
