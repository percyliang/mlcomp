MLcomp is a website for automatic and standarized execution of algorithms on
datasets.  It is now no longer active.  You are encouraged to use [CodaLab
Worksheets](https://worksheets.codalab.org); all the MLcomp datasets and
programs have been uploaded to [this CodaLab
worksheet](https://worksheets.codalab.org/worksheets/0x8b6d86f8d6a345dca607bd6d861951af/).

This README will give you instructions for running your own local copy of the
website.

Important: always source the rc file in this directory prior to running any of
the following commands.  In bash, type:

    . ./rc

### Installation

MLcomp requires the following packages:

- ruby (version >= 1.8.7)
- rubygems (version >= 1.3.7)
- libopenssl-ruby
- mongrel (version >= 1.1.5)
- mysql-server (version >= 5.1.54)

On Ubuntu, these can be installed with the following command:

    sudo apt-get install ruby rubygems libopenssl-ruby mongrel mysql-server

You will also need to install some Ruby gems:

    gem install -v=2.1.1 rails
    gem install json
    gem install mysql
    gem install packages/rails_sql_views-0.7.0.gem # We provide this file

Now we need to create the MLcomp database.  Note: you need the mysql root
password to do this.  If you don't have it, ask your system administrator to
run the commands in the script for you:

    ./init-db

Next, we update the database to the correct schema by running the Rails
migrations:

    ./update-db

Finally, we seed the database with initial programs and datasets:

    ./seed-db

Now you can run MLcomp by typing:

    ./run-web-server # Starts the Rails web server (on port 3000 by default)

You should be able point your browser to http://localhost:3000 and see the
MLcomp website.

The next step is to start the MLcomp master and workers so that you can
actually create runs.  To start the master, simply type in a different terminal
from the web server:

    ./run-master

You can start MLcomp workers on any machines that you can ssh into from the
master without a password.  To do this, run ssh-keygen on the master and append
.ssh/id_rsa.pub to .ssh/authorized_keys on the worker.  Copy the worker directory
into to the worker machine, and run:

    cd worker && ./worker -server <master hostname>

Optional: on the master, you can run a process that periodically updates the
database with general statistics about the programs/datasets (e.g., ratings):

    ./run-stats

Optional: on the master, you can run a process that enables command-line access
to MLcomp (via the mlcomp-tool):

    ./run-command-server

And that's it!  And now you should be able to create runs on your local
website.  The master will dispatch the runs to the workers, and the results
will be sent back.

### Relevant directories

- site: where the Rails webserver and code reside
- var: DO NOT MODIFY -- this is where MLcomp stores programs/datasets/runs
 which have been uploaded and is synchronized with the database.
- domains: specification files for each domain in system along with helper
 programs and sample datasets to be uploaded.

To update MLcomp, type:

    git pull
    cd site && ./update-db

Handy database commands:

    mysql -u rails_user mlcomp_development # Inspect the database
    mysqldump -u rails_user mlcomp_development > mlcomp_development.backup # Dump database to a file
    mysql -u rails_user < mlcomp_development.backup # Overwrite database with file (be careful!)

### Worker software:

MLcomp programs uploaded by the user will require various software packages to
run.  MLcomp workers need to have these packages installed:

    http://mlcomp.org/help/worker_info.html

These can be installed on Ubuntu by running:

    sudo apt-get install g++ mono-runtime ruby r-base-core octave3.2 clisp guile-1.8 ocaml ghc6 python-numpy python-scipy

Also install Sun Java 1.7 and Scala 2.9 manually.
