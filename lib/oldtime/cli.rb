require "thor"

module Oldtime
  class CLI < Thor
    include Thor::Actions

    # check_unknown_options!

    # default_task :install
    class_option "no-color", :type => :boolean, :banner => "Disable colorization in output"
    class_option "verbose",  :aliases => "-V", :type => :boolean, :banner => "Enable verbose output mode"
    class_option "dir", :aliases => "-d", :type => :string, :banner => "config directory. default is /oldtime/oldtime"
    class_option "log", :type => :string, :banner => "log file. default is /var/log/oldtime.<profile>.log"
    class_option "halt", :aliases => "-h", :default => false, :type => :boolean, :banner => "halt system after process completed. "
    class_option "after", :aliases => "-a", :type => :array, :banner => "after hook."
    class_option "before", :aliases => "-b", :type => :array, :banner => "before hook."

    def initialize(*)
      super
      o = options.dup
      the_shell = (o["no-color"] ? Thor::Shell::Basic.new : shell)
      Oldtime.ui = UI::Shell.new(the_shell)
      Oldtime.ui.debug! if o["verbose"]

      home = Rc.p.home = o["dir"] || Rc.p.home
      homerc = Rc.p.homerc = Pa("#{home}rc")

      Rc << Optimism.require(homerc.absolute2)
    end

    desc "backup <profile> [instance]", "begin backup process."
    # method_option "x", :aliases => "-x", :default => "x", :type => :string, :banner => "NAME", :desc => "x"
    def backup(profile, instance=:default)
      run(:backup, profile, instance, options.dup)
    end

    desc "restore <profile> [instance]", "begin restore process."
    def restore(profile, instance=:default)
      run(:restore, profile, instance, options.dup)
    end

private

    def run(action, profile, instance, o)
      o[:before] ||= []
      o[:after] ||= []
      Rc.action = action
      Rc.profile = profile
      instance = Rc.instance = instance.to_sym
      Rc.p.logfile = o[:log] || Pa("/var/log/oldtime.#{Rc.profile}.log")
      load_profile profile

      o[:after] << "halt" if o.halt?

      Instance.new(action, instance, o[:before].uniq, o[:after].uniq).run
    end

    def load_profile(profile)
     file = Pa("#{Rc.p.home}/#{profile}.conf")

     if file.exists?
        load file.p
      else
        raise Error, "can't find the profile configuration file -- #{file}"
      end
    end
  end
end
