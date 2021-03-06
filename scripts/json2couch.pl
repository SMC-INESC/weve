#!/usr/bin/env perl

use strict; 
use warnings;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;
use JSON;
use MIME::Types;
use CouchDB::Client;
use File::Spec;
use version; our $VERSION = qv('0.0.2');

my $result = GetOptions(
    \%ARGV,
    'input|i=s', 'output|o=s', 'error|e=s',
    'uri|u=s', 'db|d=s', 'attachments|a',
    _meta_options( \%ARGV ),
);

my ( $INH, $OUTH, $ERRH ) = _prepare_io( \%ARGV, \@ARGV );

my $ua = LWP::UserAgent->new(
    agent => "json2couch/$VERSION",
#    env_proxy => 1,
);

my $server = CouchDB::Client->new(
    uri => $ARGV{uri},
    ua => $ua,
);

$server->testConnection or die "Server $ARGV{uri} cannot be reached";

my $db = $server->newDB($ARGV{db});

$server->dbExists($ARGV{db}) or $db->create;

my $json_data = get_json($ARGV{input});

while (my ($name, $data) = each %$json_data) {

    my $doc = $db->newDoc($name);
    $doc->data($data);

    walk_hash(
        $data,
        sub {
            my ($h, $k, $v) = @_;
            if ('ARRAY' eq ref $v) {
                for my $derefv (@$v) {
                    if (defined $derefv and -e $derefv and $ARGV{attachments}) {
                        $doc->addAttachment(
                            (File::Spec->splitpath($derefv))[2],
                            MIME::Types->new->mimeTypeOf($derefv)->type,
                            get_binary($derefv)
                        );
                        delete $h->{$k};
                    }
                }
            }
        }
    );
    $doc->create;
}


sub get_binary {
    local $/;
    open my $FILE, '<', shift or die $!;
    binmode $FILE;
    return <$FILE>;
}

sub get_json {
    local $/;
    open my $FILE, '<', shift or die $!;
    return decode_json(<$FILE>);
}

sub walk_hash {
    my ($hashref, $code) = @_;

    while (my ($k, $v) = each(%$hashref)) {

        if ('HASH' eq ref $v) {
            walk_hash($v, $code);
        }
        else {
            $code->($hashref, $k, $v);
        }
    }
}

sub _meta_options {
    my ($opt) = @_;

    return (
        'quiet'     => sub { $opt->{quiet}   = 1;          $opt->{verbose} = 0 },
        'verbose:i' => sub { $opt->{verbose} = $_[1] // 1; $opt->{quiet}   = 0 },
        'version'   => sub { pod2usage( -sections => ['VERSION', 'REVISION'],
                                        -verbose  => 99 )                      },
        'license'   => sub { pod2usage( -sections => ['AUTHOR', 'COPYRIGHT'],
                                        -verbose  => 99 )                      },
        'usage'     => sub { pod2usage( -sections => ['SYNOPSIS'],
                                        -verbose  => 99 )                      },
        'help'      => sub { pod2usage( -verbose  => 1  )                      },
        'manual'    => sub { pod2usage( -verbose  => 2  )                      },
    );
}

sub _prepare_io {
    my ($opt, $argv) = @_;

    my ($INH, $OUTH, $ERRH);
    
    # If user explicitly sets -i, put the argument in @$argv
    unshift @$argv, $opt->{input} if exists $opt->{input};

    # Allow in-situ arguments (equal input and output filenames)
    if (    exists $opt->{input} and exists $opt->{output}
               and $opt->{input} eq $opt->{output} ) {
        open $INH, q{<}, $opt->{input}
            or die "Can't read $opt->{input}: $!";
        unlink $opt->{output};
    }
    else { $INH = *STDIN }

    # Redirect STDOUT to a file if so specified
    if ( exists $opt->{output} and q{-} ne $opt->{output} ) {
        open $OUTH, q{>}, $opt->{output}
            or die "Can't write $opt->{output}: $!";
    }
    else { $OUTH = *STDOUT }

    # Log STDERR if so specified
    if ( exists $opt->{error} and q{-} ne $opt->{error} ) {
        open $ERRH, q{>}, $opt->{error}
            or die "Can't write $opt->{error}: $!";
    }
    elsif ( exists $opt->{quiet} and $opt->{quiet} ) {
        use File::Spec;
        open $ERRH, q{>}, File::Spec->devnull
            or die "Can't write $opt->{error}: $!";
    }
    else { $ERRH = *STDERR }

    return ( $INH, $OUTH, *STDERR = $ERRH );
}


__END__


=head1 NAME

 json2couch - Upload a JSON document to a CouchDB server


=head1 SYNOPSIS

 json2couch [OPTION]... [-d, --db DB] [-u, --uri URI] [[-i, --input] INPUTJSON] 


=head1 DESCRIPTION

 Traverses a JSON document, assuming each top-level key to be a document name.
 If -a, --attachments is given, considers any value that is a string representing
 a filename that exists in the filesystem to be an attachment, and considers it
 as such. Uploads each document/key in input JSON to a CouchDB server, as well
 as any binary data found as an attachment.
 

=head1 OPTIONS

 -i,  --input   [string] (STDIN)                 input JSON filename  
 -u,  --uri     [string] (http://localhost:5984) CouchDB server uri
 -d,  --db      [string] ()                      CouchDB database name
 -a,  --attachments [string]                     attach top-level file paths 
      --verbose    [integer]              verbose error messages
      --quiet                             no warning messages
      --version                           print current version
      --license                           author and copyright
      --help                              print this information
      --usage                             usage only
      --options                           options only
      --manual                            complete manual page


=head1 VERSION

 0.0.2


=head1 AUTHOR

 Pedro Silva <pasilva@inescporto.pt>
 Sound and Music Computing Group
 Telecommunications and Multimedia Group
 INESC Porto


=head1 COPYRIGHT

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
