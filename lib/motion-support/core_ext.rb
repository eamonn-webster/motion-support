require 'motion_support_files'
Motion::Project::App.setup do |app|
  app.files.unshift(MotionSupport.core_ext_files)
end
