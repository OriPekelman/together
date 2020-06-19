if ARGV.empty?
  puts "together can run multiple processes, together, such as that they live and die together.
  
  Usage: 
  together \"sleep 5\" \"sleep 10\"
  If any of the processes die, together will kill the others
  If it receives a SIGTERM or a SIGINT it will kill the spawned processes
  "
  exit
end

processes = {} of Int64 => Process

Signal::TERM.trap do 
  Signal::TERM.reset
  kill_all(processes)
end

Signal::INT.trap do
  Signal::INT.reset
  kill_all(processes)
end


def run_cmd(cmd)
  proc = Process.new(cmd, shell: true,  output: STDOUT, error: Process::Redirect::Inherit) 
  puts "Running #{cmd} as [#{proc.pid}]"
  proc
end

def kill_all(processes)
   processes.each do |pid, child_process|
       if child_process.exists? 
         child_process.close
         child_process.signal(Signal::TERM)
         begin
           child_process.wait
         rescue
           puts "#{pid} no longer there"
         end
         if #{child_process.terminated?} 
           puts "killed #{pid}"
         end
       end
       processes.delete(pid)
   end
   exit()
end

ARGV.each_with_index  do |arg, i|
  spawn do
    child_process = run_cmd(arg)
    processes[child_process.pid] = child_process
    status = processes[child_process.pid].wait
    puts "#{child_process.pid} died"
    processes.delete(child_process.pid)
    if processes.empty?
      exit
    else
      puts "attempting to kill siblings"
      kill_all(processes)
    end
   end
end

puts "Supervising processes: #{processes.keys}"

at_exit{kill_all(processes); puts "Terminated"} 

while processes
  Fiber.yield
end