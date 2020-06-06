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
