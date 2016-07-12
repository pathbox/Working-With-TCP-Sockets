require 'socket'
require_relative 'common'

module FTP
	class Preforking
		include common

		CONCURRENCY = 4

		def run
			child_ pids = []
			CONCURRENCY.times do
				child_pids << spawn_child
			end

			trap(:INT){
				child_pids.each do |cpid|
					begin
						Process.kill(:INT, cpid)
					rescue Errno::ESRCH
					end
				end

				exit
			}
			loop do
				pid = Process.wait
				$stderr.puts "Process #{pid} quit unexpectedly"

				child_pids.delete(pid)
				child_pids << spawn_child
			end
		end

		def spawn_child
			fork do
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

server = FTP::Preforking.new(4481)
server.run


# Some preforking servers, notably Unicorn 2, have the parent process take a more active role in monitoring its children. 
# For example, the parent may look to see if any of the children are taking a long time to process a request. In that 
# case the parent process will forcefully kill the child process and spawn a new one in its place
