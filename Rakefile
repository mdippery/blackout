def xcodebuild(configuration)
  sh "xcodebuild -project Blackout.xcodeproj -target Blackout -configuration #{configuration} build"
end

def xcodeclean(configuration)
  sh "xcodebuild -project Blackout.xcodeproj -alltargets -configuration #{configuration} clean"
end

def agvtool(subcommand)
  sh "agvtool #{subcommand}"
end

desc "Build a release version"
task :default do
  xcodebuild 'Release'
end

desc "Build a debug version"
task :debug do
  xcodebuild 'Debug'
end

desc "Clean the project"
task :clean do
  xcodeclean 'Debug'
  xcodeclean 'Release'
end

desc "Bumps the version number"
task :bump_version do
  agvtool 'next-version -all'
end
