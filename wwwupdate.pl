#! perl
# wwwupdate.pl
# $Id: wwwupdate.PL,v 1.02 2000/07/08 06:04:23 jims Exp $
# by Jim Smyser 

=head1 NAME

wwwupdate.pl -- Automated WWW::Search backend updater

=head1 SYNOPSIS

perl wwwupdate.pl

That's it, no command line arguments.

=head1 DESCRIPTION

I<wwwupdate.pl> is a simple perl script to aid in keeping WWW::Search
backends updated as well as the core modules (Search.pm, etc.) without
having to manually do so through CPAN or other means. Frankly, CPAN is
not ideal for WWW::Search mainteance because of the frequency of
requiring new individule modules (at least not for the author). I
always end up having to manually copy backends or be aware when a
backend is available and go through the CPAN commands to retrieve. So, I
wrote this to relieve my pain and suffering in keeping my backends up to
date without any effort on my part :)

Essentially, unless there is a NEW backend, one never has to
theoritically ever have to download WWW::Search again since this will
keep it entirely up to date even when there is a new Search.pm.

What I would do is cron this script to run at least once daily or more
depending on how critical it is for you maintain working backends.
Windows users can use taskmanager under NT/Win98 for this or some other
task scheduler. You can also just run it manually from a command line.

=head1 CAVEATS

The script will update all WWW::Search directories found on the disk.
For those who have stray copies of WWW::Search on their drive that is
not doing anything like in the .cpan build directory, should remove them
to prevent the script from attempting to update backends found there.

Win32 users should beaware that ActiveState copies the backends with READ
ONLY attributes. If you are running ActiveState you should make sure the
READ ONLY is removed from the backends or this script will be useless.

=head1 TESTING

To test the script to make sure it works okay on your system you can
open say Excite.pm with a text editor and lower the $VERSION #.## and
execute the script. If it is working as designed you will see a STDOUT
message indicating Excite.pm has been updated with a more recent
version.

=head1 AUTHOR

wwwupdate.pl was written entierly by Jim Smyser E<lt><jsmyser@bigfoot.com><gt>.

=head1 BUGS

THIS SCRIPT SHOULD BE CONSIDERED BETA

Being a first release and the fact I was not sure from the beginning
how this should be coded, and no feedback yet on how it will function on
different systems, there may will be room for modifications. I only been
able to test this under Win98 and RedHat. Improvement suggestions are
welcomed.

=head1 CHANGES

version 1.02 is a first public release.

=cut
#`

$VERSION = '1.02';
use File::Find; 
use Net::FTP; 
use File::Copy; 
use Cwd;
my $current_dir = cwd;
$| = 1; 


# I am going to make a temp working dir off the current working dir
$temp_dir = "$current_dir/tmp";
mkdir("$temp_dir", 0777); 

$host = "204.201.216.36"; 
$ftp = Net::FTP->new($host); 
print "Connected to $host...\n"; 
$ftp->login("anonymous","guess\@who.com");
print "Logged In to $host....\n"; 
$ftp->cwd("/backends");
$dir = $ftp->ls(); 
print "Got Remote List...\n"; 
finddepth(\&doit, @INC); 

sub doit { 

if ($File::Find::dir =~ 
                       /WWW/ || 
                       /WWW\/Search/ || 
                       /WWW\/Search\/AltaVista/ || 
                       /WWW\/Search\/Excite/ || 
                       /WWW\/Search\/Infoseek/) {

$file = $_; 
next unless ($file =~ /\.pm/);
open(DATA,"$file") if ($file =~ /\.pm/);

while (<DATA>) {
 
# Get the version 
if (m/^\$VERSION.*?(\d.+)('|")/) { 
$Local_VERSION = $1; 
} 
} 
close (DATA);

foreach $line (@$dir) { 
next unless ($file =~ /\.pm/);
next if (!$line =~ /$file/);
if ($line =~ /$file/) 
{ 
$ftp->type("ascii");
$mod = $ftp->get("$line", "$temp_dir/$line"); 
open(MOD, "$temp_dir/$line") || die "Can't open downloaded $line: $!\n"; 
while (<MOD>) { 
if (m/^\$VERSION.*?(\d.+)('|")/) { 
$Remote_VERSION = $1; 
} 
} 
close (MOD);
print "Version of $file: Remote: $Remote_VERSION Local: $Local_VERSION \n"; 

if ($Remote_VERSION > $Local_VERSION) { 
$undo = unlink("$File::Find::dir/$file"); 

if (!($undo)) { 
} else { 
move("$temp_dir/$line", "./$line"); 
print "$file has been updated with a more recent version...\n"; 
}}}}}}
# clean up the temp dir to conserve space
unlink <$temp_dir/*.*>;

exit;

