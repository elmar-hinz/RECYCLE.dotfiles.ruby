#! /usr/bin/env ruby

##################################################
# Configuration
##################################################

$target = '~/.rubydotfiles'
$repository = 'git@github.com:elmar-hinz/dotfiles.git'
$title = 'El Dotfilejero'

##################################################
# Library
##################################################

module Mvc

    def model=(model)
        @@model = model
    end

    def model()
        return @@model
    end

    def view=(view)
        @@view = view
    end

    def view()
        return @@view
    end

    def controller=(controller)
        @@controller = controller
    end

    def controller()
        return @@controller
    end

end

class App
    include Mvc

    def initialize()
        self.model = Dotfiles.new($repository, $target)  
        self.view = View::Pane.new(nil, $title)
        self.controller = Controller.new()
    end

    def self.main() 
        App.new.controller.loop
    end
end

##################################################
# Model
##################################################

class Dotfiles

    attr_accessor :repository, :target

    def initialize(repository, target)
        self.repository = repository
        self.target = target
    end

    def clone()
        puts "Cloning #{@repository} into #{@target}."
        %x(git clone #{@repository} #{@target})
    end

end

##################################################
# View
##################################################

module View

    module Draw

        def boldline()
            return '###########################################################################' + nl
        end

        def nl()
            return "\n"
        end

        def indent()
            return "\t"
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
        include Mvc

        def initialize(parent)
            @parent = parent
            @states = {}
            @current = :default
        end

        def parent()
            return @parent
        end

        def parent=(parent)
            @parent = parent
        end

        def root()
            return (parent() == nil) ? self : parent()
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
       
        def draw()
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

        def draw
            connectController()
            return super()
        end
        
        def connectController
            controller().action = @action
            controller().prompt = @prompt 
            controller().preset = @preset
        end

    end

    class Header < Component

        def initialize(parent, title)
            super(parent)
            @title = title 
        end

        def drawBody
            return head $title
        end
        
    end
    
    class Dict < Component
        def initialize(parent, key, value)
            super(parent)
            @key = key 
            @value = value
        end

        def drawBody 
            return indent + '* ' + @key + ': ' + @value + nl 
        end
    end

    class Par < Component

        def initialize(parent, msg)
            super(parent)
            @msg = msg
        end

        def drawBody 
            return indent + @msg + nl 
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

        def initialize(parent, title)
            super(parent)
            # header and footer only set the default
            # while the default of body is empty
            header.push Header.new(self, title)
            header.push Dict.new(self, 'Reopsitory', model.repository)
            header.push Dict.new(self, 'Target', model.target)
            header.push Par.new(self, '') 
            body(:menu).push Menu.new(self)
            body(:quit).push GoodBy.new(self)
            footer.push Footer.new(self)
        end

    end

    class Menu < ActionComponent
        def initialize(parent)
            super(parent)
            @action = :menuAction
            @prompt = 'Please select a menu item by number'
            @preset = ''
            body.push(Par.new(self, '0) Quit')) 
            body.push(Par.new(self, '1) Clone Repository')) 
            body.push(Par.new(self, '9) Cleanup')) 
        end
    end

    class GoodBy < ActionComponent
        def initialize(parent)
            super(parent)
            @action = :quitAction
            @prompt = ''
            @preset = ''
            body.push(Par.new(self, 'Good by')) 
        end
    end

end

##################################################
# Controller
##################################################

class Controller
    
    include Mvc
    attr_accessor :action, :prompt, :preset

    def initialize()
        @action = :defaultAction
        @prompt = ''
        @preset = ''
        @loop = true;
    end

    def loop
        input = ''
        while @loop
            print `clear` 
            action(input)
            print view().draw()
            input = prompt() unless @action == :quitAction 
        end
    end

    def prompt
        puts
        puts 'Type quit to exit.'
        puts
        puts @prompt
        print 'Default: "' + @preset + '" > '
        input = gets.strip
        return (input == '') ? @preset : input
    end

    def action input 
        @action = :quitAction if input == 'quit' 
        # puts 'Action: ' + @action.to_s
        send(@action, input)
    end

    def defaultAction input
       view().switch :menu 
    end

    def menuAction input
        case input.to_i
        when 1
            puts 'Cloning' 
            view().switch :menu 
        when 9
            puts 'Cleaning' 
            view().switch :menu 
        when 0
            view().switch :quit 
        else
            view().switch :menu 
        end
    end

    def quitAction input
       view().switch :quit 
       @loop = false 
    end

end

##################################################
# Run
##################################################

App.main()

##################################################
# The End
##################################################

