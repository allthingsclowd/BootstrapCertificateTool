# encoding: utf-8
# copyright: 2020, Graham Land

title 'Verify BootStrapMe.sh Options'


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

  describe directory('/usr/local/bootstrap/.bootstrap/CA/SSH/Bananas') do
    it { should exist }
  end
  
  describe command('ssh-keygen -L -f /usr/local/bootstrap/.bootstrap/CA/SSH/Bananas/Bananas-ssh-rsa-ca.pub') do
    its('stdout') { should match /Valid/ }
  end

end

control 'verify-ssl-initialise-option-c' do                      
  impact 1.0                                
  title 'Option -C -n <ssl root ca name>'
  desc 'verify option -c (create new SSL root CA) is working.'
  
  describe command('/usr/local/bootstrap/scripts/BootStrapMe.sh -C -n Oranges') do
    its('exit_status') { should eq 0 }
  end

  describe directory('/usr/local/bootstrap/.bootstrap/CA/SSL/Oranges') do
    it { should exist }
  end
  
  describe command('ssh-keygen -L -f /usr/local/bootstrap/.bootstrap/CA/SSL/Oranges/ORANGES-ssh-rsa-ca.pub') do
    its('stdout') { should match /Valid/ }
  end
end



