require 'socket'
require 'thread'
require_relative 'common'

module FTP
	class ThreadPool
		include Common

		CONCURRENCY = 25

		def run
			Thread.abort_on_exception = true
			threads = ThreadGroup.new
			CONCURRENCY.times do
				threads.add spawn_thread
			end

			sleep
		end

		def spawn_thread
			Thread.new do
				loop do
					@client = @control_socket.accept
					respond "220 OHAI"

					handler = CommondHandler.new(self)
					loop do
						request = @client.gets(CRLF)
						if request
							respond handler.handle(request)
						else
							@client.close
							break
						end
					end
				end
			end
		end
	end
end

server = FTP::ThreadPool.new(4481)
server.run

# This method creates a ThreadGroup to keep track of all the threads. ThreadGroup is a bit like a thread-aware Array. You add threads to the ThreadGroup , but when a member thread finishes execution it's silently dropped from the group.
# You can use ThreadGroup#list to get a list of all the threads currently in the group, all of which will be active. We don't actually use this in this implementation but ThreadGroup would be useful if we wanted to act on all active threads (to join them, for instance).
# Much like in the last chapter, we simply call the method as many times as CONCURRENCY calls for. Notice how the number is higher here than in
# Preforking? Again, that's because threads are lighter weight and, therefore, we can have more of them. Just keep in mind that the MRI GIL mitigates some of this gain.
# The end of this method calls sleep to prevent it from exiting. The main thread remains idle while the pool does the work. Theoretically it could be doing its own work monitoring the pool, but here it just sleep s to prevent it from exiting.