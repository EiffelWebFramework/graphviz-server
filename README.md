This GraphViz server is meant to be a real case example of Eiffel Web Framework
and a great testbed for RESTful Hypermedia API.

keywords:REST,HATEOS,HAL,caching,authentication,logging,graphviz

Application: provide a graphviz description, and get in return jpg, png, pdf, svg, ... output

See http://www.graphviz.org/

For more information please have a look at the related wiki:

* https://github.com/EiffelWebFramework/graphviz-server/wiki

## Requirements
* [Graphviz](http://www.graphviz.org/): On Debian/Ubuntu, you can just *sudo apt-get install graphviz*

## Run

Before you run the Graphviz server, you first have to define the environment variable *GRAPHVIZ_DOT_DIR*.
This should be the folder containing the *dot* binary (on Debian/Ubuntu, it is */usr/bin*).
