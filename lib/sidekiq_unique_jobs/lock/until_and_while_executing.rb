# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Locks jobs while the job is executing in the server process
    # - Locks on perform_in or perform_async (see {UntilExecuting})
    # - Unlocks before yielding to the worker's perform method (see {UntilExecuting})
    # - Locks before yielding to the worker's perform method (see {WhileExecuting})
    # - Unlocks after yielding to the worker's perform method (see {WhileExecuting})
    #
    # See {#lock} for more information about the client.
    # See {#execute} for more information about the server
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class UntilAndWhileExecuting < BaseLock
      # Executes in the Sidekiq server process
      # @yield to the worker class perform method
      def execute
        if unlock
          lock_on_failure do
            runtime_lock.execute { return yield }
          end
        else
          log_warn("Couldn't unlock digest: #{item[LOCK_DIGEST]}, jid: #{item[JID]}")
        end
      end

      private

      def lock_on_failure
        yield
      rescue Exception # rubocop:disable Lint/RescueException
        log_error("Runtime lock failed to execute job, restoring server lock", item)
        lock
        raise
      end

      def runtime_lock
        @runtime_lock ||= SidekiqUniqueJobs::Lock::WhileExecuting.new(item, callback, redis_pool)
      end
    end
  end
end
