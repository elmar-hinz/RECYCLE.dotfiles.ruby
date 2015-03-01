#! /usr/bin/env ruby

##################################################
# Configuration
##################################################

$target = '~/.rubydotfiles'
$repository = 'git@github.com:elmar-hinz/dotfiles.git'
$title = 'El Dotfiliereo'

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

    def initialize()
       @controller = Controller.new()
    end

    def run() 
        @controller.loop()
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

class Controller
    
    def self.action
        return @@action
    end

    def self.action=(action)
        @@action = action
    end

    def self.prompt
        return @@prompt
    end

    def self.prompt=(prompt)
        @@prompt = prompt
    end

    def self.preset
        return @@preset
    end

    def self.preset=(preset)
        @@preset = preset
    end

    def initialize()
        Controller.action = :defaultAction
        Controller.prompt = ''
        Controller.preset = ''
        @loop = true;
        @pane = View::Pane.new()
    end

    def loop
        input = ''
        while @loop
            print `clear` 
            action(input)
            print @pane.draw()
            input = prompt() unless Controller.action == :quitAction 
        end
    end

    def prompt
        prompt = ' > '
        puts
        puts 'Type quit to exit.'
        puts
        puts Controller.prompt
        print 'Default: "' + Controller.preset + '"' + prompt
        input = gets.strip
        return (input == '') ? Controller.preset : input
    end

    def action input 
        Controller.action = :defaultAction unless Controller.action
        Controller.action = :quitAction if input == 'quit' 
        self.send(Controller.action)
    end

    def defaultAction
       @pane.switch :menu 
    end

    def menuAction
        @pane.switch :menu 
    end

    def quitAction
       @pane.switch :quit 
       @loop = false 
    end

end

module View

    module Draw

        def boldline()
            return '###########################################################################' + nl
        end

        def nl()
            return "\n"
        end

        def head(title)
            return boldline + '# ' + title + nl + boldline + nl
        end

    end

    # parts should always be set for the :default state
    # parts can be set for dedicated states
    # this works per part (header, body, footer)
    class Component

        include Draw

        def initialize()
            @states = {}
            @current = :default
        end

        def switch(current)
            @current = current
        end

        def header(state = :default)
            return state(state)[:header]
        end
       
        def body(state = :default)
            return state(state)[:body]
        end
       
        def footer(state = :default)
            return state(state)[:footer]
        end
       
        def draw
            return drawHeader() + drawBody() + drawFooter()
        end
        
        def drawHeader()
            return drawPart(:header)
        end

        def drawBody()
            return drawPart(:body)
        end

        def drawFooter()
            return drawPart(:footer)
        end

        private

        def state(state)
            unless @states[state]
                @states[state] = { header: [], body: [], footer: [] }
            end
            return @states[state]
        end

        def drawPart(key) 
            fields = state(@current)[key] 
            fields = state(:default)[key] if fields.empty? 
            lines = '' 
            fields.each() { |child| 
                child.switch @current
                lines = lines + child.draw(); 
            }
            return lines
        end
    end

    class ActionComponent < Component

        def connectController
            Controller.action = @action
            Controller.prompt = @prompt 
            Controller.preset = @preset
        end

        def draw
            connectController()
            return super()
        end
        
    end

    class Header < Component

        def initialize(title)
            super()
            @title = title 
        end

        def drawBody
            return head $title
        end
        
    end
    
    class Paragraph < Component

        def initialize(msg)
            super()
            @msg = msg
        end

        def drawBody 
            return @msg + nl 
        end
    end

    class Footer < Component

        def drawBody
            lines = ""
            lines = lines + nl()
            lines = lines + boldline()
            lines = lines + boldline()
            return lines
        end
        
    end
    
    ##################################################

    class Pane < Component

        def initialize()
            super()
            header(:default).push(Header.new($title)) 
            body(:menu).push(Menu.new());
            body(:quit).push(GoodBy.new());
            footer(:default).push(Footer.new()) 
        end

    end

    class Menu < ActionComponent
        def initialize
            super()
            @action = :menuAction
            @prompt = 'Please select a menu item'
            @preset = ''
            body().push(Paragraph.new('1) Topic 1')) 
            body().push(Paragraph.new('2) Topic 2')) 
        end
    end

    class GoodBy < ActionComponent
        def initialize
            super()
            @action = :quitAction
            @prompt = ''
            @preset = ''
            body().push(Paragraph.new('Good by')) 
        end
    end

end

##################################################
# Run
##################################################

Dotfiles.new().run()

##################################################
# End
##################################################

