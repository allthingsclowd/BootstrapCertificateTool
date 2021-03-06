# encoding: utf-8
# copyright: 2020, Graham Land

title 'Verify BootStrapMe.sh Options'

base_dir = attribute('base_dir', value: '/usr/local/bootstrap', description: 'Configure working directory for Inspec tests in Travis-CI')

control 'audit_installation_prerequisites' do
  impact 1.0
  title 'os and packages'
  desc 'verify os type and base os packages'

  describe os.family do
    it {should eq 'debian'}
  end

  describe package('golang-cfssl') do
    it {should be_installed}
  end


end

control 'verify-the-script-exists' do         
  impact 1.0                      
  title 'BootStrapMe.sh exists'
  desc 'verify that the BootstrapMe.sh script has been installed correctly'
  describe file('/usr/local/bootstrap/scripts/BootStrapMe.sh') do 
    it { should exist }
  end
end

control 'verify-nuke-option-Z-assert' do                      
  impact 1.0                                
  title 'Option -Z'
  desc 'verify option -Z (delete everything) is working when option 1 is selected'
  describe command('echo 1 | /usr/local/bootstrap/scripts/BootStrapMe.sh -Z') do
    its('exit_status') { should eq 0 }
  end
end

control 'verify-nuke-option-Z-cancel' do                      
  impact 1.0                                
  title 'Option -Z'
  desc 'verify option -Z (delete everything) is working when option 2 is selected'
  describe command('echo 2 | /usr/local/bootstrap/scripts/BootStrapMe.sh -Z') do
    its('exit_status') { should eq 1 }
  end
end

control 'verify-ssh-initialise-option-c' do                      
  impact 1.0                                
  title 'Option -c -n <ssh root ca name>'
  desc 'verify option -c (create new SSH root CA) is working.'
  describe command('/usr/local/bootstrap/scripts/BootStrapMe.sh -c -n Bananas') do
    its('exit_status') { should eq 0 }
  end

  describe directory(base_dir + '/.bootstrap/CA/SSH/Bananas') do
    it { should exist }
  end

  describe file(base_dir + '/.bootstrap/CA/SSH/Bananas/Bananas-ssh-rsa-ca.pub') do
    it { should exist }
  end
  
  describe file(base_dir + '/.bootstrap/CA/SSH/Bananas/Bananas-ssh-rsa-ca') do
    it { should exist }
  end 
  
  describe command('ssh-keygen -l -f ' + base_dir + '/.bootstrap/CA/SSH/Bananas/Bananas-ssh-rsa-ca.pub') do
    its('exit_status') { should eq 0 }
  end

end

control 'verify-ssh-initialise-rerun' do                      
  impact 1.0                                
  title 'Already initialised? Then Stop!'
  desc 'verify option -c does not RESET the CA if one already exists'
  
  describe file(base_dir + '/.bootstrap/CA/SSH/Bananas/Bananas-ssh-rsa-ca.pub') do
    it { should exist }
  end
  
  describe file(base_dir + '/.bootstrap/CA/SSH/Bananas/Bananas-ssh-rsa-ca') do
    it { should exist }
  end   
  
  describe command('/usr/local/bootstrap/scripts/BootStrapMe.sh -c -n Bananas') do
    its('exit_status') { should eq 0 }
    #its('stdout') { should match /found/ }
  end

end

control 'create-ssh-host-keys' do                      
  impact 1.0                                
  title 'Create SSH Host Keys for the suplied Hostname'
  desc 'create new host keys for a server'
  
  describe file(base_dir + '/.bootstrap/CA/SSH/Bananas/Bananas-ssh-rsa-ca.pub') do
    it { should exist }
  end
  
  describe file(base_dir + '/.bootstrap/CA/SSH/Bananas/Bananas-ssh-rsa-ca') do
    it { should exist }
  end   
  
  describe command('/usr/local/bootstrap/scripts/BootStrapMe.sh \
            -H \
            -n Bananas \
            -h grazzer') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /completed/ }
  end

  describe command('/usr/local/bootstrap/scripts/BootStrapMe.sh \
            -H \
            -n Bananas \
            -h grazzer \
            -s') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /completed/ }
  end
  
  describe file(base_dir + '/.bootstrap/Key/SSH/Bananas/grazzer-ssh-rsa-host-key') do
    it { should exist }
  end
  
  describe file(base_dir + '/.bootstrap/Key/SSH/Bananas/grazzer-ssh-rsa-host-key.pub') do
    it { should exist }
  end
  
  describe file(base_dir + '/.bootstrap/Key/SSH/Bananas/grazzer-ssh-rsa-host-key-cert.pub') do
    it { should exist }
  end
  
  describe command('ssh-keygen -l -f ' + base_dir + '/.bootstrap/Key/SSH/Bananas/grazzer-ssh-rsa-host-key-cert.pub') do
    its('exit_status') { should eq 0 }
  end

  describe command('/usr/local/bootstrap/scripts/BootStrapMe.sh \
            -H \
            -n TOMATOES \
            -h grazzer \
            -s') do
    its('exit_status') { should eq 1 }
    its('stdout') { should match /BANG/ }
  end

end

control 'create-ssh-user-keys' do                      
  impact 1.0                                
  title 'Create SSH User Keys for the suplied User'
  desc 'create new user ssh keys'
  
  describe file(base_dir + '/.bootstrap/CA/SSH/Bananas/Bananas-ssh-rsa-ca.pub') do
    it { should exist }
  end
  
  describe file(base_dir + '/.bootstrap/CA/SSH/Bananas/Bananas-ssh-rsa-ca') do
    it { should exist }
  end   
  
  describe command('/usr/local/bootstrap/scripts/BootStrapMe.sh \
            -U \
            -n Bananas \
            -u grazzer \
            -b graz,pi,graham') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /completed/ }
  end
  
  describe file(base_dir + '/.bootstrap/Key/SSH/Bananas/grazzer-id_rsa') do
    it { should exist }
  end
  
  describe file(base_dir + '/.bootstrap/Key/SSH/Bananas/grazzer-id_rsa.pub') do
    it { should exist }
  end
  
  describe file(base_dir + '/.bootstrap/Key/SSH/Bananas/grazzer-id_rsa-cert.pub') do
    it { should exist }
  end
  
  describe command('ssh-keygen -l -f ' + base_dir + '/.bootstrap/Key/SSH/Bananas/grazzer-id_rsa-cert.pub') do
    its('exit_status') { should eq 0 }
  end

  describe command('/usr/local/bootstrap/scripts/BootStrapMe.sh \
            -U \
            -n Bananas \
            -u grazzer \
            -b graz,pi,graham
            -s') do
    its('exit_status') { should eq 127 }
  end

  describe command('/usr/local/bootstrap/scripts/BootStrapMe.sh \
            -U \
            -n EGGS \
            -u grazzer \
            -b graz,pi,graham
            -s') do
    its('exit_status') { should eq 127 }
    its('stdout') { should match /BANG/ }
  end

end


#control 'verify-ssl-initialise-option-c' do                      
#  impact 1.0                                
#  title 'Option -C -n <ssl root ca name>'
#  desc 'verify option -c (create new SSL root CA) is working.'
#  
#  describe command('/usr/local/bootstrap/scripts/BootStrapMe.sh -C -n Oranges') do
#    its('exit_status') { should eq 0 }
#  end

#  describe directory('/usr/local/bootstrap/.bootstrap/CA/SSL/Oranges') do
#    it { should exist }
#  end
  
#  describe command('ssh-keygen -L -f /usr/local/bootstrap/.bootstrap/CA/SSL/Oranges/ORANGES-ssh-rsa-ca.pub') do
#    its('stdout') { should match /Valid/ }
#  end
#end



