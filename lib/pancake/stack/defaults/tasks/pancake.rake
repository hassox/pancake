namespace :pancake do
  desc "symlink all public files to the current public directory"
  task :symlink_to_public do
    puts "Symlinking files to public"
    THIS_STACK.stackup
    THIS_STACK.symlink_public_files!
    puts "Done"
  end
end
