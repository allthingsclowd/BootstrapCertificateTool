info = <<-'EOF'

      Certificate creation process for demo labs
        
                on Vagrant



WARNING: PLEASE DON'T USE THESE CERTIFICATES IN ANYTHING OTHER THAN THIS TEST LAB!!!!
The keys are clearly publically available for demonstration purposes.

I am NOT a PKI guru or have ANY Qualifications what-so-ever in the certificate security space. Do not use any of these examples near production without first getting inputs from a security subject matter expert.
With the disclaimer out of the way I use these certificates to facilitate illustrating how one can work with the HashiCorp products when they have TLS enabled.
Most online examples tend to default to HTTP only for brevity and clarity and assume adding TLS is trivial....I never find adding TLS trivial without access to a Subject Matter Expert :)
If you're curious about the bias in any of my blogs, repos, tweets, etc - I work for HashiCorp as a Customer Success Manager in EMEA - yes I'm biased!

Hope this was helpful!

Graham
https://allthingscloud.eu

EOF

Vagrant.configure("2") do |config|

    #override global variables to fit Vagrant setup
    ENV['CERT_SERVER']||="cert-server01"
    ENV['CERT_SERVER_IP']||="192.168.0.5"

    
    #global config
    config.vm.synced_folder ".", "/usr/local/bootstrap"
    config.vm.box = "allthingscloud/web-page-counter"
    #config.vm.box_version = "0.2.1568383863"

    config.vm.provider "virtualbox" do |v|
        v.memory = 1024
        v.cpus = 2
    end

    config.vm.define "leader01" do |leader01|
        leader01.vm.hostname = ENV['CERT_SERVER']
        leader01.vm.network "private_network", ip: ENV['CERT_SERVER_IP']
    end


   puts info if ARGV[0] == "status"

end

