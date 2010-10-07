PROJECT = 'Blackout.xcodeproj'
TARGET  = 'Blackout'

def xcodebuild(project, target, configuration)
  sh "xcodebuild -project #{project} -target #{target} -configuration #{configuration} build"
end

def xcodeclean(project, configuration)
  sh "xcodebuild -project #{project} -alltargets -configuration #{configuration} clean"
end

def agvtool
  sh "agvtool next-version -all"
end

desc "Build a release version"
task :default do
  xcodebuild PROJECT, TARGET, 'Release'
end

desc "Build a debug version"
task :debug do
  xcodebuild PROJECT, TARGET, 'Debug'
end

desc "Clean the project"
task :clean do
  xcodeclean PROJECT, 'Debug'
  xcodeclean PROJECT, 'Release'
end

desc "Bumps the version number"
task :bump_version do
  agvtool
end
