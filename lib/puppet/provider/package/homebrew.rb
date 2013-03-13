require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:homebrew, :parent => Puppet::Provider::Package) do
  desc "Package management using Homebrew on OS X."

  confine :operatingsystem => :darwin

  has_feature :installable
  has_feature :versionable
  has_feature :upgradeable
  has_feature :uninstallable

  commands :id   => "/usr/bin/id"
  commands :stat => "/usr/bin/stat"
  commands :sudo => "/usr/bin/sudo"
  commands :brew => "/usr/local/bin/brew"

  # Homebrew can't (and shouldn't!) be run as root; Puppet can (and often
  # should) be run as root.  When running as root, we'll make a best effort to
  # run as someone else -- specifically, the owner of /usr/local/bin/brew.
  #
  # TODO: Can we simply refuse to act if run by root?  That would simplify
  # things a quite a bit...
  def self.execute(cmd)
    owner = super([command(:stat), '-nf', '%Uu', command(:brew)]).to_i
    env = { 'HOME' => "/Users/" + super([command(:id), '-un', owner]).chomp }
    if super([command(:id), '-u']).to_i.zero?
      super(cmd, :uid => owner, :failonfail => true, :combine => true, :custom_environment => env)
    else
      super(cmd, :failonfail => true, :combine => true, :custom_environment => env)
    end
  end

  def self.instance_hashes(options={})
    cmd = [command(:brew), "list", "--versions", options[:justme]].compact

    begin
      list = execute(cmd).split("\n")
      list.collect! { |line| line.split }
      list.reject!  { |line| line.length < 2 }
      list.collect! do |line|
        { :provider => :homebrew, :name => line.first, :ensure => line.last }
      end
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not list brews: #{detail}"
    end

    options[:justme] ? list.first : list
  end

  def self.instances
    return instance_hashes.collect { |hash| self.new(hash) }
  end

  def execute(*args); self.class.execute(*args); end

  def uninstall
    execute([command(:brew), :uninstall, @resource[:name]])
  end

  def query
    self.class.instance_hashes(:justme => resource[:name])
  end

  def latest
    info = execute([command(:brew), :info, "#{@resource[:name]}"])
    return nil if $CHILD_STATUS != 0 or info =~ /^Error/
    return 'HEAD' if info =~ /\bHEAD\b/
    return info.lines[0].split[0]
  end

  def install
    @resource.should(:ensure)

    args = [:install, @resource[:name]]
    args << '--force' << '--HEAD' if @resource[:ensure] == :latest

    result = execute([command(:brew), *args])
    if result =~ /^Error: No available formula/
      raise Puppet::ExecutionFailure, "Could not find package #{@resource[:name]}"
    end
  end
  alias :update :install
end
