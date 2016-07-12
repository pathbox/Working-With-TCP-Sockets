require 'socket'
require_relative 'common'

module FTP
	class ProcessPerConnection
		include Common

		def run
			loop do
				@client = @control_socket.accept
				pid = fork do  #fork 一个新的进程来处理 请求
					respond "220 OHAI"
					handler = CommondHandler.new(slef)
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
				Process.detach(pid)
			end
		end
	end
end

server = FTP::ProcessPerConnection.new(4481)
server.run

# Immediately after accept ing a connection the server process calls fork with a block. The
# new child process will evaluate that block and then exit.
# This means that each incoming connection gets handled by a single, independent process. 
# The parent process will not evaluate the code in the block; it just continues along the execution path.