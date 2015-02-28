#! /usr/bin/env ruby

##################################################
# Configuration
##################################################

$target = '~/.rubydotfiles'
$repository = 'git@github.com:elmar-hinz/dotfiles.git'

##################################################
# Library
##################################################

module Messanger

    def self.ok? key, value
        puts ''
        puts key + ': ' + value 
        print 'Is this O.K.? (yes, no) > '
        answer = gets.chomp
        self.die (key + ': ' + value) unless answer == 'yes' 
    end

    def self.ask(msg, default = "")
        prompt = " > "
        print msg
        print " (default: #{default})" unless default.empty?
        print prompt
        result = gets.strip
        return result.empty? ? default : result
    end

    def self.speak(msg)
        puts msg
    end

    def self.warn(msg)
        puts "Warning: " + msg
    end
    
    def self.error(msg)
        puts "Error: " + msg
    end
    
    def self.die(msg)
        puts "Exit: " + msg
        exit(1)
    end
end

class Dotfiles

    def run() 
        prompt()
        clone()
    end

    def prompt()
        @repository = Messanger.ask 'Clone repository:', $repository
        @target = Messanger.ask 'Target directory:', $target
        Messanger.ok? 'Repsitory', @repository
        Messanger.ok? 'Target', @target
    end

    def clone()
        puts "Cloning #{@repository} into #{@target}."
        %x(git clone #{@repository} #{@target})
    end

end

##################################################
# Run
##################################################

Dotfiles.new().run()

##################################################
# End
##################################################

