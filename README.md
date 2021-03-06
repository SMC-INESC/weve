## Weve - Automated listening tests

![](./weve.png)

This is a CouchApp for conducting automated listening tests
online. CouchApps are web applications which can be served directly
from [CouchDB](http://couchdb.apache.org). This gives them the nice
property of replicating just like any other data stored in
CouchDB. They are also simple to write as they can use the built-in
jQuery libraries and plugins that ship with CouchDB.

[More info about CouchApps here.](http://couchapp.org)

## Application structure

`weve` is divided into two parts: static pages and the application
itself. The static pages live under the `_attachments` folder. The
default flow is as follows:

- `welcome.html` - Landing page, it should explain the purpose of the experiment.
- `instructions.html` - The constraints of the design should be explained here.
- `training.html` - This page provides an example of the mechanics of the application.
- `index.html` - This is the javascript application itself.
- `finish.html` - Concluding remarks.

Currently, the flow from page to page is hard-coded in these pages
through forms that submit to the next page. The samples to be played
back in `training.html` are also hardcoded, and should exist in the
design document as attachments.

The javascript application itself is under `_attachments/js`. It is
currently configured by editing the `JSON` file `config.json` in the
root directory. Here is a schema of the various configurable
bits:

    {"min": [
        "Integer: complete disagreement with the question in the Likert item",
        "String: descriptive statement for complete disagreement in the Likert item"
    ],
     "max": [
         "Integer: complete agreement with the question in the Likert item",
         "String: descriptive statement for complete agreement in the Likert item"
     ],
     "value": [
         "Integer: default non-rated agreement level in the Likert item",
         "String: descriptive statement for default non-rated agreement in the Likert item"
     ],
     "step": "Integer: agreement interval in the Likert item",
     "question": "String: default generic question to which each Likert item refers",
     "words": [
         "String: name of the Likert item",
         "String: specific question to which this Likert item refers",
         "String: descriptive statement for complement disagreement in this Likert word",
         "String: descriptive statement for complement agreement in this Likert word"
     ],
     "submit": "String: label of widget that changes stimuli"}

This configuration file is used to generate the application at
`index.html` and `js/app.js`.

## Experiment structure

The included `Makefile`, in the root directory, contains suitable
targets for generating, uploading, retrieving, and preparing the
resulting data for analysis. Here's an overview of the available
targets:

- `help` - print this information
- `usage` - print usage information
- `targets` - print available targets
- `variables` - print available variables
- `experiment` - prepare local filesystem, generate and upload design document
- `analyze` - dump participants and ratings as a repeated measures/within-subjects `csv` document
- `cleanup` - delete participant and ratings data from the server
- `clean` - delete local output directory
- `check` - ensure all dependencies are met
- `dir` - create local experiment filesystem
- `convert` - convert audio files `$AUDIO_DIR/*.$AUDIO_EXT` to `mp3`, `m4a`, and `oga`
- `design` - generate `couchdb` design document from local filesystem
- `deploy` - upload the `weve` design document to the server
- `upload` - upload audio files as attachments to the server
- `participants` - dump series of participant data as `json` documents
- `ratings` - dump series of ratings data as `json` documents
- `table` - generate repeated measures/within-subjects `csv` document from participant and ratings data
- `delete-participants` - delete participant data from `couchdb` server
- `delete-ratings` - delete ratings data from `couchdb` server

Here is a complete list of `Make` variables you can set, together with
their default values:

- `FFMPEG` - `/usr/bin/ffmpeg`
- `PERL` - `/usr/bin/perl`
- `COUCHAPP` - `/usr/bin/couchapp`
- `FS2JSON` - `scripts/fs2json.pl`
- `JSON2COUCH` - `scripts/json2couch.pl`
- `COUCH2CSV` - `scripts/couch2csv.pl`
- `OUT_DIR` - `out`
- `AUDIO_DIR` - `in`
- `AUDIO_EXT` - `wav`
- `COUCHAPP_ENV` - `default`
- `COUCHAPP_RC` - `.couchapprc`
- `COUCHAPP_HOST` - Extract from `COUCHAPP_RC`
- `COUCHAPP_DB` - `Extract from `COUCHAPP_RC`

And here are some usage examples:

    make AUDIO_DIR=/some/audio/files/dir OUT_DIR=/some/output/dir experiment # upload experiment
    make OUT_DIR=/some/output/dir analyze                                    # download data
    make OUT_DIR=/some/output/dir clean                                      # delete local data
    make cleanup                                                             # delete remote data

## Deployment

> [Note that the following is exactly what is run with `make deploy`]

Assuming you just cloned this app from git, and you have changed into
the app directory in your terminal, you want to push it to your
CouchDB with the CouchApp command line tool, like this:

    couchapp push . http://name:password@hostname:5984/mydatabase

If you don't have a password on your CouchDB (admin party) you can do
it like this (but it's a bad, idea, set a password):

    couchapp push . http://hostname:5984/mydatabase

If you get sick of typing the URL, you should setup a `.couchapprc`
file in the root of your directory. Remember not to check this into
version control as it will have passwords in it.

The `.couchapprc` file should have contents like this:

    {
      "env" : {
        "public" : {
          "db" : "http://name:pass@mycouch.couchone.com/mydatabase"
        },
        "default" : {
          "db" : "http://name:pass@localhost:5984/mydatabase"
        }
      }
    }

Now that you have the `.couchapprc` file set up, you can push your app
to the CouchDB as simply as:

    couchapp push

This pushes to the `default` as specified. To push to the `public`
you'd run:

    couchapp push public

Of course you can continue to add more deployment targets as you see
fit, and give them whatever names you like.

## Dependencies

`weve` has been developed and tested on `Linux`, but should work on
any `Unix`-like system. It obviously requires a `CouchDB` server with
administrative priviledges to create databases and, locally, the
following programs:

- `ffmpeg` - http://ffmpeg.org/
- `curl` - http://curl.haxx.se/
- `jshon` - http://kmkeen.com/jshon/
- `couchapp` - http://couchapp.org
- `perl` - http://www.perl.org/

Additionally, the Perl programs in the `scripts` directory require the
following modules:

- `CouchDB::Client` - http://search.cpan.org/perldoc?CouchDB%3A%3AClient
- `DateTime::Format::Strptime` - http://search.cpan.org/perldoc?DateTime%3A%3AFormat%3A%3AStrptime
- `JSON` - http://search.cpan.org/perldoc?JSON
- `MIME::Types` - http://search.cpan.org/perldoc?MIME%3A%3ATypes
- `URI::Escape` - http://search.cpan.org/perldoc?URI%3A%3AEscape
