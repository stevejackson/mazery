## About

[Mazery](http://mazery.sjackson.net) is a maze generation visualizer project written in CoffeeScript.

Why? Because maze generation is fun to watch!

## Setup

If you want to fork it and fool around, it's easy. The site runs on [middleman](https://github.com/tdreyno/middleman),
a simple static site generator.

    gem install bundler
    bundle install
  
Now you're all set up. When you want to run the server, which autocompiles the coffeescript/sass etc files into /build
as they're edited, run:

    middleman
  
That's it! Your server is now running and can be accessed at:

    localhost:4567

Your generated site is now in /build.