def xcodebuild(conf)
  sh "xcodebuild -project Blackout.xcodeproj -target Blackout -configuration #{conf.to_s.capitalize} build"
end

def xcodeclean(conf)
  sh "xcodebuild -project Blackout.xcodeproj -alltargets -configuration #{conf.to_s.capitalize} clean"
end

def agvtool(subcommand)
  sh "agvtool #{subcommand}"
end

desc "Build a release version"
task :default do
  xcodebuild :release
end

desc "Build a debug version"
task :debug do
  xcodebuild :debug
end

desc "Clean the project"
task :clean do
  xcodeclean :debug
  xcodeclean :release
end

desc "Bumps the version number"
task :bump_version do
  agvtool 'next-version -all'
end
