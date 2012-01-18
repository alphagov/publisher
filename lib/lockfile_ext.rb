# PATCH - make Lockfile gem work in ruby 1.9

require 'lockfile'
class Lockfile
    alias_method :old_load_lock_id, :load_lock_id
    def load_lock_id buf
      def buf.each(&block)
        self.split($/).each(&block)
      end
      old_load_lock_id buf
    end
end
