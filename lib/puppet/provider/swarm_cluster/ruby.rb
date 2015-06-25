require 'socket'
require 'resolv'

Puppet::Type.type(:swarm_cluster).provide(:ruby) do
  desc "Support for Docker Swarm"
  
  mk_resource_methods

  commands :swarm => "swarm"   

  def interface
    hostname = Socket.gethostname
    IPSocket.getaddress(hostname) 
  end

  def swarm_conf
    cluster = resource[:cluster_type] 
    backend = (resource[:backend])
    address = (resource[:address])
    port = (resource[:port])  
    path = (resource[:path])
    case 
      when cluster.match(/create/)
        yield 'create'
        'create' 
      when cluster.match(/join/)
        ['join', "--advertise=#{interface}:2375", "#{backend}://#{address}:#{port}/#{path}"]
      when cluster.match(/manage/)      
        ['manage', '-H', "tcp://#{interface}:2375", "#{backend}://#{address}:#{port}/#{path}"]   
      end
   end

   def exists?
      Puppet.info("Checking if swarm is running")
       pid = `ps -ef | grep swarm | grep -v grep`   
       ! pid.length.eql? 0
   end
 
   def create
     Puppet.info("Configuring Swarm Cluster")
     p = fork {swarm *swarm_conf}
     Process.detach(p)
   end

   def destroy
     Puppet.info("stoping swarm")
     `pidof swarm | xargs kill -9 $1`
   end
end