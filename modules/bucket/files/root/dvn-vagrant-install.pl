#!/usr/bin/perl

use Getopt::Long;
use Socket; 
use File::Copy;

my( %opts ) = ( );
my( $rez ) = GetOptions( \%opts, "pg_only!");

if ( $opts{$pg_only} )
{
    print "Please do not use the dev. installer in --pg_only mode! \n";
    print "In order to populate a database on a remote server, please use \n";
    print "the *main* installer script (\"install --pg_only\") instead.\n\n";
     
    exit 1;
}



my @CONFIG_VARIABLES = (); 

@CONFIG_VARIABLES = (       
#	    'HOST_DNS_ADDRESS',
    'GLASSFISH_DIRECTORY',
    
    'POSTGRES_SERVER',
    'POSTGRES_PORT',
    'POSTGRES_DATABASE',
    'POSTGRES_USER',
    'POSTGRES_PASSWORD',
    
    'RSERVE_HOST',
    'RSERVE_PORT',
    'RSERVE_USER',
    'RSERVE_PASSWORD'

    ); 

my %CONFIG_DEFAULTS = 
    (       
#	    'HOST_DNS_ADDRESS', 'localhost',
	    'GLASSFISH_DIRECTORY', '/opt/glassfish',

	    'POSTGRES_SERVER',  'localhost',
	    'POSTGRES_PORT',    5432,
	    'POSTGRES_DATABASE','dvnDb',
	    'POSTGRES_USER',    'dvnApp',
	    'POSTGRES_PASSWORD','secret',

	    'RSERVE_HOST',      'dvndb-qa1.hmdc.harvard.edu',
	    'RSERVE_PORT',      6311,
	    'RSERVE_USER',      'rserve',
	    'RSERVE_PASSWORD',  'rserve'

	    ); 


my %CONFIG_PROMPTS = 
    (       
#	    'HOST_DNS_ADDRESS', "Internet Address of your host \n(we recommend to use \"localhost\" for a dev installation): \n",
	    'GLASSFISH_DIRECTORY', 'Glassfish Directory', 

	    'POSTGRES_SERVER',  'Postgres Server (localhost recommended for a dev. installation!)',
	    'POSTGRES_PORT',    'Postgres Server Port',
	    'POSTGRES_DATABASE','Name of the Postgres Database',
	    'POSTGRES_USER',    'Name of the Postgres User (we recommend that you use the default name dvnApp)',
	    'POSTGRES_PASSWORD','Postgres user password',

	    'RSERVE_HOST',      'Rserve Server',
	    'RSERVE_PORT',      'Rserve Server Port',
	    'RSERVE_USER',      'Rserve User Name',
	    'RSERVE_PASSWORD',  'Rserve User Password'

	    ); 

# Supported Posstgres JDBC drivers: 
# (have to be configured explicitely, so that Perl "taint" (security) mode 
# doesn't get paranoid)

my $POSTGRES_DRIVER_8_3 = "postgresql-8.3-603.jdbc4.jar";  
my $POSTGRES_DRIVER_8_4 = "postgresql-8.4-703.jdbc4.jar";
my $POSTGRES_DRIVER_9_0 = "postgresql-9.0-802.jdbc4.jar";
my $POSTGRES_DRIVER_9_1 = "postgresql-9.1-902.jdbc4.jar";

# A few preliminary checks: 

# user -- must be root: 

$user_real = `who am i`; 
chop $user_real; 
$user_real =~s/ .*$//; 


if ( $< != 0 ) 
{
    print STDERR "\nERROR: You must be logged in as root to run the installer.\n\n";


    exit 1; 
}

# OS: 

my $uname_out = `uname -a`; 


print "\nWelcome to the DVN *Development Environment* installer.\n";

print "You will be guided through the process of setting up a NEW\n";
print "instance of the DVN apoplication as part of a development \n";
print "environment. \n";
print "(NOTE, that this installer should NOT be used to upgrade an\n";
print "existing DVN installation, or if you are not setting up a \n";
print "personal development environment!)\n";

my @uname_tokens = split (" ", $uname_out); 

if ( $uname_tokens[0] eq "Darwin" )
{
    print "\nThis appears to be a MacOS X system; good.\n";
    # TODO: check the OS version

    $WORKING_OS = "MacOSX"; 
}
elsif ( $uname_tokens[0] eq "Linux" )
{
    if ( -f "/etc/redhat-release" )
    {
	#print "\nThis appears to be a RedHat system; good.\n";
	print "\nThis appears to be a RedHat system;\n";
	print "WARNING: This is an experimental version of the installer,\n";
	print "at this point it has been tested on MacOS X only.\n";
	print "Proceed at your own risk!\n";
	$WORKING_OS = "RedHat"; 
	# TODO: check the distro version
    }
    else 
    {
	print "\nThis appears to be a non-RedHat Linux system;\n";
	print "this installation *may* succeed; but we're not making any promises!\n";
	$WORKING_OS = "Linux"; 
    }
} 
else 
{
    print "\nWARNING: This appears to be neither a Linux or MacOS X system!\n";
    print "This installer script will most likely fail. Please refer to the\n";
    print "DVN Installers Guide for more information.\n\n";

    $WORKING_OS = "Unknown";

    print "Do you wish to continue?\n [y/n] ";


    my $yesnocont = <>; chop $yesnocont;

    while ( $yesnocont ne "y" && $yesnocont ne "n" )
    {
	print "Please enter 'y' or 'n'!\n";
	print "(or ctrl-C to exit the installer)\n";
	$yesnocont = <>; chop $yesnocont;
    }

    if ( $yesnocont eq "n" )
    {
	exit 0;
    }

}

 ENTERCONFIG: 

print "\n";
print "Please enter the following configuration values:\n";
print "(hit [RETURN] to accept the default value)\n";
print "\n";

for $ENTRY (@CONFIG_VARIABLES)
{
    print $CONFIG_PROMPTS{$ENTRY} . ": \n";
    print "[" . $CONFIG_DEFAULTS{$ENTRY} . "] ";

    $user_entry = ""; 
    chop $user_entry; 

    if ($user_entry ne "")
    {
	$CONFIG_DEFAULTS{$ENTRY} = $user_entry;
    }

    print "\n";
}

# CONFIRM VALUES ENTERED: 


print "\nOK, please confirm what you've entered:\n\n";

for $ENTRY (@CONFIG_VARIABLES)
{
    print $CONFIG_PROMPTS{$ENTRY} . ": " . $CONFIG_DEFAULTS{$ENTRY} . "\n";
}

print "\nIs this correct? [y/n] ";


my $yesno = "y";

while ( $yesno ne "y" && $yesno ne "n" )
{
    print "Please enter 'y' or 'n'!\n";
    print "(or ctrl-C to exit the installer)\n";
    $yesno = <>; chop $yesno;  
    $yesno = "y";
}

if ( $yesno eq "n" )
{
    goto ENTERCONFIG; 
}

# FOR DEV SYSTEM, HOST IS ALWAYS LOCALHOST: 

$CONFIG_DEFAULTS{'HOST_DNS_ADDRESS'} = 'localhost';

# VALIDATION/VERIFICATION OF THE CONFIGURATION VALUES: 

# 1. NO MAIL SERVER CHECK FOR THE DEV VERSION 
# (smtp.hmdc.harvard.edu pre-configured)

# 2. CHECK IF THE WAR FILE IS AVAILABLE:

unless ( -f "../../../src/DVN-web/dist/DVN-web.war" )
{
    print "\nWARNING: Can't find the project .war file in ../../../src/DVN-web/dist/!\n";
    print "\tAre you running the installer in the right directory?\n";
    print "\tHave you built the war file?\n";
    print "\t(if not, build the project and run the installer again)\n";
    
    exit 0; 
}

# check the working (installer) dir:
chomp($cwd = `pwd`);


# 3. CHECK POSTGRES AVAILABILITY: 

my $pg_local_connection = 0; 

if ( $CONFIG_DEFAULTS{'POSTGRES_SERVER'} eq 'localhost' )
{
    $pg_local_connection = 1; 

    # 3a. CHECK FOR USER postgres:

    print "\nChecking system user \"postgres\"... ";

    $POSTGRES_SYS_NAME = "postgres";
    $POSTGRES_SYS_UID = (getpwnam ("postgres"))[2]; 

    if ($POSTGRES_SYS_UID == undef) {
	print STDERR "\nERROR: I haven't been able to find user \"postgres\" on the system!\n";
	print STDERR "(TODO: prompt the user instead to supply an alternative username, if\n";
	print STDERR "available)\n";

	exit 1; 
    } 

    print "OK.\n";

    # 3b. LOCATE THE EXECUTABLE:

    $sys_path = $ENV{'PATH'}; 
    @sys_path_dirs = split ( ":", $sys_path ); 

    $psql_exec = ""; 

    for $sys_path_dir ( @sys_path_dirs )
    {
	if ( -x $sys_path_dir . "/psql" ) 
	{
	    $psql_exec = $sys_path_dir; 
	    last; 
	}
    }

    $pg_major_version = 0;
    $pg_minor_version = 0;

    if ( $psql_exec eq "" && $WORKING_OS eq "MacOSX" )
    {
	for $pg_minor_version ( "1", "0" )
	{
	    if ( -x "/Library/PostgreSQL/9." . $pg_minor_version . "/bin/psql" ) 
	    {
		$psql_exec = "/Library/PostgreSQL/9." . $pg_minor_version . "/bin";
		last; 
	    }
	}	
	for $pg_minor_version ( "4", "3" )
	{
	    if ( -x "/Library/PostgreSQL/8." . $pg_minor_version . "/bin/psql" ) 
	    {
		$psql_exec = "/Library/PostgreSQL/8." . $pg_minor_version . "/bin";
		last; 
	    }
	}
    }

    if ( $psql_exec eq "" )
    {
	print STDERR "\nERROR: I haven't been able to find the psql command in your PATH!\n";
	print STDERR "Please make sure PostgresQL is properly installed and try again.\n\n";

	exit 1; 
    }

    # 3c. CHECK POSTGRES VERSION: 

    open (PSQLOUT, $psql_exec . "/psql --version|"); 

    $psql_version_line = <PSQLOUT>; 
    chop $psql_version_line; 
    close PSQLOUT; 

    my ($postgresName, $postgresNameLong, $postgresVersion) = split ( " ", $psql_version_line ); 

    unless ( $postgresName eq "psql" && $postgresVersion =~ /^[0-9][0-9\.]*$/ )
    {
	print STDERR "\nERROR: Unexpected output from psql command!\n";
	print STDERR "Please make sure PostgresQL is properly installed and try again.\n\n";

	exit 1; 
    }


    my (@postgres_version_tokens) = split ( '\.', $postgresVersion ); 

    unless ( ($postgres_version_tokens[0] == 8 && $postgres_version_tokens[1] >= 3) || ($postgres_version_tokens[0] >= 9) )
    {
	print STDERR "\nERROR: PostgresQL version 8.3, or newer, is required!\n";
	print STDERR "Found a copy of psql ($psql_exec/psql) that belongs to version $postgresVersion.\n\n";
	print STDERR "Please make sure the right version of PostgresQL is properly installed,\n";
	print STDERR "and the right version of psql comes first in the PATH,\n";
	print STDERR "then try again.\n";

	exit 1; 
    }

    print "\n\nFound Postgres psql command, version $postgresVersion. Good.\n\n";

    $pg_major_version = $postgres_version_tokens[0];
    $pg_minor_version = $postgres_version_tokens[1];

    # 4. CONFIGURE POSTGRES: 

    print "\nConfiguring Postgres Database:\n";


    # 4b. CHECK IF THE SQL FILES ARE IN PLACE: 

    $SQL_FILE_DIRECTORY = "../../../src/DVN-EJB/src/conf";
    $SQL_REFERENCE_DATA_FILE = "referenceData.sql"; 
    $SQL_REFERENCE_DATA = $SQL_FILE_DIRECTORY . "/" . $SQL_REFERENCE_DATA_FILE;

    unless ( -f $SQL_REFERENCE_DATA )
    {
	print "\nWARNING: Can't find .sql files in ../../../src/DVN-EJB/src/conf!\n"; 
	print "(are you running the installer in the right directory?)\n";
    
	exit 0; 
    }

    # 4a. CHECK IF POSTGRES IS RUNNING:
    print "Checking if a local instance of Postgres is running and accessible...\n";

    # (change to /tmp before switching user to postgres and executing 
    # the command below -
    # we are trying to do it as user postgres, and it may not have
    # access to the current, installer directory; the command would still
    # work, but there would be an error message from the shell init on screen
    # - potentially confusing)
    chdir ("/tmp");
    $< = $POSTGRES_SYS_UID; 
    $> = $POSTGRES_SYS_UID; 

    if (!system ($psql_exec . "/psql -c 'SELECT * FROM pg_roles' > /dev/null 2>&1"))
    {
	print "Yes, it is.\n";
    }
    else
    {
	print "Nope, I haven't been able to connect to the local instance of PostgresQL.\n";
	print "daemon. Is postgresql running? \n";
	print "On a RedHat system, you can check the status of the daemon with\n\n";
	print "   service postgresql status\n\n";
	print "and, if it's not running, start the daemon with\n\n";
	print "   service postgresql start\n\n";
	print "On MacOSX, use Applications -> PostgresQL -> Start Server.\n";
	print "Also, please make sure that the daemon is listening to network connections,\n";
	print "at leaset on the localhost interface. (See \"Installing Postgres\" section\n";
	print "of the installation manual).\n";
	print "Finally, please make sure that the postgres user can make localhost \n";
	print "connections without supplying a password. (That's controlled by the \n";
	print "\"localhost ... ident\" line in pg_hba.conf; again, please consult the \n";
	print "installation manual).\n";


	exit 1; 
    }


    # 4c. CHECK IF THIS DB ALREADY EXISTS:

    $psql_command_dbcheck = $psql_exec . "/psql -c \"\" -d " . $CONFIG_DEFAULTS{'POSTGRES_DATABASE'} . " > /dev/null 2>&1"; 
    if ( ($exitcode = system($psql_command_dbcheck)) == 0 )
    {
	print "WARNING! Database " . $CONFIG_DEFAULTS{'POSTGRES_DATABASE'} . " already exists!\n";
	print "\nDo you want to DESTROY this database? [y/n] ";

	$yesnocont = "y";

	while ( $yesnocont ne "y" && $yesnocont ne "n" )
	{
	    print "Please enter 'y' or 'n'!\n";
	    print "(or ctrl-C to exit the installer)\n";
	    $yesnocont = "y";
	}

	if ( $yesnocont eq "n" )
	{
	    print "\nOK. Aborting the installation.\n";
	    print "(please choose a different database name and try again).\n";
	    exit 0;
	}

	$psql_command_drop = $psql_exec . "/dropdb " . $CONFIG_DEFAULTS{'POSTGRES_DATABASE'};
	unless ( ($exitcode = system($psql_command_drop)) == 0 )
	{
	    print STDERR "\nERROR: Could not destroy the database.\n";
	    print STDERR "Aborting the installation.\n";
	    exit 1; 
	}
    }

    # 4d. Check if this USER already exists:

    $psql_command_rolecheck = $psql_exec . "/psql -c \"\" -d postgres " . $CONFIG_DEFAULTS{'POSTGRES_USER'} . " > /dev/null 2>&1";
    if ( ($exitcode = system($psql_command_rolecheck)) == 0 )
    {
	print "User (role) . " . $CONFIG_DEFAULTS{'POSTGRES_USER'} . " already exists;\n";
	print "Proceeding.";
    }
    else 
    {
	# 4e. CREATE DVN DB USER:

	print "\nCreating Postgres user (role) for the DVN:\n";

	open TMPCMD, ">/tmp/pgcmd.$$.tmp";
	
	# with unencrypted password: 
	#print TMPCMD "CREATE ROLE ".$CONFIG_DEFAULTS{'POSTGRES_USER'}." UNENCRYPTED PASSWORD '".$CONFIG_DEFAULTS{'POSTGRES_PASSWORD'}."' NOSUPERUSER CREATEDB CREATEROLE NOINHERIT LOGIN";
	
	# with md5-encrypted password:
	$pg_password_md5 = &create_pg_hash ($CONFIG_DEFAULTS{'POSTGRES_USER'},$CONFIG_DEFAULTS{'POSTGRES_PASSWORD'}); 
	my $sql_command = "CREATE ROLE \"".$CONFIG_DEFAULTS{'POSTGRES_USER'}."\" PASSWORD 'md5". $pg_password_md5 ."' NOSUPERUSER CREATEDB CREATEROLE INHERIT LOGIN";
	
	print TMPCMD $sql_command; 
	close TMPCMD; 

	my $psql_commandline = $psql_exec . "/psql -f /tmp/pgcmd.$$.tmp";
	
	unless ( ($exitcode = system($psql_commandline)) == 0 )
	{
	    print STDERR "Could not create the DVN Postgres user role!\n";
	    print STDERR "(SQL: " . $sql_command . ")\n";
	    print STDERR "(psql exit code: " . $exitcode . ")\n";
	    exit 1; 
	}

	unlink "/tmp/pgcmd.$$.tmp";
	print "done.\n";
    }
    
    # 4f. CREATE DVN DB: 

    print "\nCreating Postgres database:\n";

    $psql_command = $psql_exec . "/createdb ".$CONFIG_DEFAULTS{'POSTGRES_DATABASE'}." --owner=".$CONFIG_DEFAULTS{'POSTGRES_USER'};

    unless ( ($exitcode = system("$psql_command")) == 0 ) 
    {
	print STDERR "Could not create Postgres database for the DVN app!\n";
	print STDERR "(command: " . $psql_command . ")\n";
	print STDERR "(psql exit code: " . $exitcode . ")\n";
	exit 1; 
	
    }

# Changing back to root UID: 

    $> = 0; 
    $< = 0;      

    chdir ($cwd);

}
else 
{
    print "\nIt is strongly recommended that you use a local PostgresQL server,\n";
    print "running on localhost, in your development environment!\n\n";

    print "Do you wish to continue?\n [y/n] ";


    my $yesnocont = <>; chop $yesnocont;

    while ( $yesnocont ne "y" && $yesnocont ne "n" )
    {
	print "Please enter 'y' or 'n'!\n";
	print "(or ctrl-C to exit the installer)\n";
	$yesnocont = <>; chop $yesnocont;
    }

    if ( $yesnocont eq "n" )
    {
	print "(aborting the installation)\n".
	exit 0;
    }


    print "In order to use a PostgresQL database running on a remote server,\n";
    print "Please run the *main* installer on that host with the \"--pg_only\" option:\n\n";
    print "./install --pg_only\n\n";

    print "Press any key to continue the installation process once that has been\n";
    print "done. Or press ctrl-C to exit the installer.\n\n";

    system "stty cbreak </dev/tty >/dev/tty 2>&1";
    #my $key = getc(STDIN);
    my $key = "y";
    system "stty -cbreak </dev/tty >/dev/tty 2>&1";
    print "\n";

    # Check if the role and database have been created on the remote server:
    # -- TODO; 

    # Find out what Postgres version is running remotely:

    $pg_major_version = 9;
    $pg_minor_version = 1;

    print "What version of PostgresQL is installed on the remote server?\n [" . $pg_major_version . "." . $pg_minor_version . "] ";


    my $postgresVersion = <>; chop $postgresVersion;

    while ( $postgresVersion ne "" && !($postgresVersion =~/^[0-9]+\.[0-9]+$/) )
    {
        print "Please enter valid Postgres version!\n";
        print "(or ctrl-C to exit the installer)\n";
        $postgresVersion = <>; chop $postgresVersion;
    }

    unless ( $postgresVersion eq "" )
    {
        my (@postgres_version_tokens) = split ( '\.', $postgresVersion );

        unless ( ($postgres_version_tokens[0] == 8 && $postgres_version_tokens[1] >= 3) || ($postgres_version_tokens[0] >= 9) )
        {
            print STDERR "\nERROR: PostgresQL version 8.3, or newer, is required!\n";
            print STDERR "Please make sure the right version of PostgresQL is properly installed\n";
            print STDERR "on the remote server, then try again.\n";

            exit 1;
        }

        $pg_major_version = $postgres_version_tokens[0];
        $pg_minor_version = $postgres_version_tokens[1];
    }

}


# 5. CONFIGURE GLASSFISH

print "\nProceeding with the Glassfish setup.\n";
print "\nChecking your Glassfish installation..."; 

my $glassfish_dir = $CONFIG_DEFAULTS{'GLASSFISH_DIRECTORY'}; 

# 5a. CHECK IF GLASSFISH DIR LOOKS OK:

unless ( -d $glassfish_dir."/glassfish/domains/domain1" )
{
    # TODO: need better check than this

    while ( ! ( -d $glassfish_dir."/glassfish/domains/domain1" ) )
    {
	print "\nInvalid Glassfish directory " . $glassfish_dir . "!\n";
	print "Enter the root directory of your Glassfish installation:\n";
	print "(Or ctrl-C to exit the installer): "; 

	$glassfish_dir = <>; 
	chop $glassfish_dir; 
    }
}

print "OK!\n";

# 5b. DETERMINE HOW MUCH MEMORY TO GIVE TO GLASSFISH AS HEAP:

$gf_heap_default = "2048m"; 
$sys_mem_total = 0; 

if ( -e "/proc/meminfo" && open MEMINFO, "/proc/meminfo" ) 
{
    # Linux 

    while ( $mline = <MEMINFO> )
    {
	if ( $mline =~ /MemTotal:[ \t]*([0-9]*) kB/ )
	{
	    $sys_mem_total = $1; 
	}
    }

    close MEMINFO; 

} 
elsif ( -x "/usr/sbin/sysctl" ) 
{
    # MacOS X, probably...

    $sys_mem_total = `/usr/sbin/sysctl -n hw.memsize`; 
    chop $sys_mem_total; 
    $sys_mem_total = ( int ($sys_mem_total / 1024) ); 
}

if ( $sys_mem_total > 0 )
{
    # setting the default heap size limit to 3/8 of the available
    # amount of memory:
    $gf_heap_default = ( int ($sys_mem_total / (8 / 3 * 1024) ) );

    print "\nSetting the heap limit for Glassfish to " . $gf_heap_default . "MB. \n"; 
    print "You may need to adjust this setting to better suit \n";
    print "your system.\n\n";

}
else 
{
    print "\nCould not determine the amount of memory on your system.\n";
    print "Setting the heap limit for Glassfish to 2GB. You may need \n"; 
    print "to  adjust the value to better suit your system.\n\n";
}

push @CONFIG_VARIABLES, "DEF_MEM_SIZE"; 
$CONFIG_DEFAULTS{"DEF_MEM_SIZE"} = $gf_heap_default; 

print "\nPress any key to continue...\n\n";

system "stty cbreak </dev/tty >/dev/tty 2>&1";
	my $key = "y";
	system "stty -cbreak </dev/tty >/dev/tty 2>&1";
	print "\n";

# 5c. GENERATE GLASSFISH CONFIGURATION FILE:

print "\nWriting glassfish configuration file (domain.xml)... ";


open TEMPLATEIN, 'domain-dev.xml.TEMPLATE'; 
open CONFIGOUT, '>domain.xml';

while( <TEMPLATEIN> )
{
    for $ENTRY (@CONFIG_VARIABLES)
    {
	$patin = '%' . $ENTRY . '%'; 
	$patout = $CONFIG_DEFAULTS{$ENTRY}; 
	
	s/$patin/$patout/g;
    }

    print CONFIGOUT $_; 

}

close TEMPLATEIN; 
close CONFIGOUT; 

print "done.\n";

system ("/bin/cp -f domain.xml ".$glassfish_dir."/glassfish/domains/domain1/config"); 
#diagnostics needed!

# check if the supllied config files are in the right place: 

unless ( -f "../../../working_directory/logging.properties" )
{
    print "\nERROR! Configuration files not found in ../../../!\n";
    print "(are you running the installer in the right directory?\n";
    print "Aborting...\n";
    exit 1; 
}

print "\nCopying additional configuration files... ";

system ( "/bin/cp -f ../../../working_directory/* ".$glassfish_dir."/glassfish/domains/domain1/config"); 
system ( "/bin/mkdir -p ".$glassfish_dir."/glassfish/domains/domain1/config/networkData/lib"); 
system ( "/bin/cp -f ../../../lib/dvn-lib-NetworkData/*.jar ".$glassfish_dir."/glassfish/domains/domain1/config/networkData/lib"); 
system ( "/bin/cp -f ../../../lib/dvn-lib-NetworkData-EXTRA/*.jar ".$glassfish_dir."/glassfish/domains/domain1/config/networkData/lib"); 
#diagnostics needed!

# install pre-configured robots.txt blocking bot crawlers:
system ( "/bin/cp -f robots.txt ".$glassfish_dir."/glassfish/domains/domain1/docroot"); 

print "done!\n";

print "\nInstalling the Glassfish PostgresQL driver... ";

my $install_driver_jar = "";

if ( $pg_major_version == 8 ) 
{
    if ( $pg_minor_version == 3 ) 
    {
        $install_driver_jar = $POSTGRES_DRIVER_8_3;
    }
    elsif ( $pg_minor_version == 4 ) 
    {
        $install_driver_jar = $POSTGRES_DRIVER_8_4;
    }
}
elsif ( $pg_major_version == 9 )
{
    if ( $pg_minor_version == 0 ) 
    {
        $install_driver_jar = $POSTGRES_DRIVER_9_0;
    }
    elsif ( $pg_minor_version == 1 ) 
    {
        $install_driver_jar = $POSTGRES_DRIVER_9_1;
    }
} 

unless ( $install_driver_jar ) 
{
    die "Installer could not find POSTGRES JDBC driver for your version of PostgresQL!\n";

} 

system ( "cp", "pgdriver/" . $install_driver_jar, $glassfish_dir."/glassfish/lib");
print "done!\n";


# 5d. STOP GLASSFISH (OK IF NOT RUNNING):
print "\nStopping glassfish...\n";

unless ( ($exit_code=system ($glassfish_dir."/bin/asadmin stop-domain domain1")) == 0 )
{
	print STDERR "(that's OK!)\n";
}

# 5dd. INSTALL PATCHED WEBCORE GLASSFISH MODULE: 

$gf_webcore_jar = $glassfish_dir."/glassfish/modules/web-core.jar";

system ("/bin/mv -f ".$gf_webcore_jar . " " . $gf_webcore_jar.".PRESERVED");
system ("/bin/cp web-core.jar ".$gf_webcore_jar); 

# 5ddd. DELETE EJB TIMER APP LOCK FILE, if exists (just in case!):

system ( "/bin/rm -f ".$glassfish_dir."/glassfish/domains/domain1/generated/ejb-timer-service-app" );


# 5e. START GLASSFISH:
print "\nStarting glassfish.\n";

unless ( ($exit_code=system ($glassfish_dir."/bin/asadmin start-domain domain1")) == 0 )
{
	print STDERR "Could not start glassfish!\n";
	print STDERR "(exit code: " . $exitcode . ")\n";
	exit 1; 
}


# check if glassfish is running: 
# TODO. 

# 6. DEPLOY APPLICATION:
# 6a. DO WE HAVE ANT? 
#  (we are no longer using ant to deply -- L.A.)
#
#$sys_path = $ENV{'PATH'}; 
#@sys_path_dirs = split ( ":", $sys_path ); 

#$ant_exec = ""; 
#
#for $sys_path_dir ( @sys_path_dirs )
#{
#    if ( -x $sys_path_dir . "/ant" ) 
#    {
#	$ant_exec = $sys_path_dir . "/ant"; 
#	last; 
#    }
#}
#
#if ( $ant_exec eq "" )
#{
#    print STDERR "\nERROR: I haven't been able to find ant command in your PATH!\n";
#    print STDERR "Please make sure and is installed and in your PATH; then try again.\n\n";
#
#    exit 1; 
#}

# 6b. TRY TO DEPLOY:
print "\nAttempting to deploy the application:\n\n";

$CONFIG_DEFAULTS{'GLASSFISH_ADMIN_PASSWORD'} = 'adminadmin'; 
# TODO: ask for password! -- in case they have already changed it
# (update: chances are we don't even need the password anymore, as 
# long as we are deploying locally (?))

my $glassfish_password = $CONFIG_DEFAULTS{'GLASSFISH_ADMIN_PASSWORD'}; 

# create deployment properties files:
#   (these properties files are no longer used, because we are no longer
#   using ant to deploy the app. -- L.A.)

#for $prop_file ('AS', 'glassfish') 
#{
#    open ( TEMPLIN, "appdeploy/" . $prop_file . ".properties.TEMPLATE" ) 
#	|| die "failed to open appdeploy/" . $prop_file . ".properties.TEMPLATE";
#    open ( PROPOUT, ">appdeploy/" . $prop_file . ".properties" ) 
#	|| die "failed to open appdeploy/" . $prop_file . ".properties for writing";
#
#    while( <TEMPLIN> )
#    {
#	s/%GF_ADMIN_PASSWORD%/$glassfish_password/g;
#	s/%GF_ROOT_DIR%/$glassfish_dir/g;
#	print PROPOUT $_; 
#    }
#
#    close TEMPLIN; 
#    close PROPOUT; 
#}

# Copy the .war file: 

system ("cp -f ../../../src/DVN-web/dist/DVN-web.war appdeploy/dist"); 

# TODO: 
# check if succeeded!

# Create the .asadminpass file, or replace it, if exists:

$asadminpass_file = $ENV{'HOME'} . "/.asadminpass";

if ( -e $asadminpass_file )
{
    system ("/bin/mv -f " . $asadminpass_file . " " . $asadminpass_file . ".PRESERVED");
}

system ("echo 'asadmin://admin@localhost:4848 ' > " . $asadminpass_file); 

$deploy_command = $glassfish_dir."/bin/asadmin deploy --force=true --name=DVN-web dist/DVN-web.war";

unless ( ($exit_code = system ("cd appdeploy; " . $deploy_command)) == 0 )
{
	print STDERR "Could not deploy DVN application!\n";
	print STDERR "(exit code: " . $exitcode . ")\n";
	exit 1; 
}

if ( $pg_local_connection )
{
    print "\nOK; now we are going to stop glassfish and populate the database with\n";
    print "some initial content.\n";
}
else
{
    print "\nOK; stopping glasfish.\n";
}


# 6c. SHUT DOWN:

$gf_stop_command = $glassfish_dir."/bin/asadmin stop-domain domain1"; 

unless ( ($exit_code = system ($gf_stop_command)) == 0 )
{
	print STDERR "Could not stop glassfish!\n";
	print STDERR "(command line: " . $gf_stop_command . ")\n";
	print STDERR "(exit code: " . $exitcode . ")\n";
	exit 1; 
}

# 7. POPULATE DATABASE:

if ( $pg_local_connection )
{
    # 7a. POPULATE LOCALLY:
    print "\nPopulating the database (local PostgresQL instance):\n\n";

    # Copy the SQL file to /tmp, where user postgres will definitely
    # have read access to it:

    open DATATEMPLATEIN, $SQL_REFERENCE_DATA || die $@;
    open SQLDATAOUT, '>/tmp/'.$SQL_REFERENCE_DATA_FILE || die $@;

    while( <DATATEMPLATEIN> )
    {
	s/dvnApp/$CONFIG_DEFAULTS{'POSTGRES_USER'}/g;
	print SQLDATAOUT $_;
    }

    close DATATEMPLATEIN;


    $< = $POSTGRES_SYS_UID; 
    $> = $POSTGRES_SYS_UID; 
    chdir ("/tmp");
    $psql_command = $psql_exec . "/psql -d $CONFIG_DEFAULTS{'POSTGRES_DATABASE'} -f " . $SQL_REFERENCE_DATA_FILE;

    unless ( ($exitcode = system("$psql_command")) == 0 ) 
    {
	print STDERR "Could not populate Postgres database for the DVN app!\n";
	print STDERR "(command: " . $psql_command . ")\n";
	print STDERR "(psql exit code: " . $exitcode . ")\n";
	print STDERR "\nYou must populate the database before you can use your new\n";
	print STDERR "DVN instance. Please consult the installation manual and/or\n";
	print STDERR "seek support from the DVN team.\n\n";
	exit 1; 
	
    }

    print "\nOK, done!\n";

}
else 
{
    # 7b. INSTRUCT THE USER TO POPULATE THE DB ON THE REMOTE SERVER: 
    # NOT SUPPORTED YET -- TODO
    print "The database needs to be populated with some intial content \n"; 
    print "before restarting the DVN. \n";
    print "However, populating a databases on a remote PostgresQL server "; 
    print "is not supported yet!\n";
    print "Please copy the file referenceData.sql (found in this directory)\n";
    print "onto the remote server and populate the database manually,\n";
    print "as user postgres, with the following command:\n\n";
    print "   psql -d $CONFIG_DEFAULTS{'POSTGRES_DATABASE'} -f referenceData.sql\n";
    print "then start glassfish again on this server with \n\n";
    print "   " . $glassfish_dir."/bin/asadmin start-domain domain1\n\n";

    $> = 0; 
    $< = 0; 

    exit 0; 
    
}

# back to root:

$> = 0; 
$< = 0; 
chdir ($cwd);

# 8. INSTRUCT THE USER TO START GLASSFISH AGAIN, MANUALLY:

# but first, a little cleanup: 
system ("chown -fR " . $user_real . " " . $glassfish_dir . "/glassfish/domains/domain1"); 

# and also, delete the EJB TIMER app lock file, if exists (just in case!):
system ( "/bin/rm -f ".$glassfish_dir."/glassfish/domains/domain1/generated/ejb-timer-service-app" );


print "\nOK, done.\n";
print "Please start glassfish again, as yourself (i.e., not as root), \n";
print "Using \n\n";
print "   " . $glassfish_dir."/bin/asadmin start-domain domain1\n\n";
print "or from Netbeans;\n";

print "\nOnce you have a running DVN instance, \n";
print "olease go to the application at the following URL:\n\n";
print "  http://" . $CONFIG_DEFAULTS{'HOST_DNS_ADDRESS'} . ":8080/dvn\n";
print "\nand log in by using \"networkAdmin\" as both the user name\n";
print "and password. Click the \"networkAdmin\" link on the right side\n";
print "Of the main screen, then click \"Update Account\". Change this\n";
print "default password and default e-mail address.\n\n";



# 9. FINALLY, CHECK IF RSERVE IS RUNNING:
if (0) { # (not necessary on a dev. system?)
print "\n\nFinally, checking if Rserve is running and accessible...\n";

unless ( $CONFIG_DEFAULTS{'RSERVE_PORT'}=~/^[0-9][0-9]*$/ )
{
    print $CONFIG_DEFAULTS{'RSERVE_HOST'} . " does not look like a valid port number,\n";
    print "defaulting to 6311.\n\n";

    $CONFIG_DEFAULTS{'RSERVE_PORT'} = 6311; 
}
    
my ( $rserve_iaddr, $rserve_paddr, $rserve_proto );

unless ( $rserve_iaddr = inet_aton($CONFIG_DEFAULTS{'RSERVE_HOST'}) )
{
    print STDERR "Could not look up $CONFIG_DEFAULTS{'RSERVE_HOST'},\n";
    print STDERR "the host you specified as your R server.\n";
    print STDERR "\nDVN can function without a working R server, but\n";
    print STDERR "much of the functionality concerning running statistics\n";
    print STDERR "and analysis on quantitative data will not be available.\n";
    print STDERR "Please consult the Installers guide for more info.\n";

    exit 0;
}

$rserve_paddr = sockaddr_in($CONFIG_DEFAULTS{'RSERVE_PORT'}, $rserve_iaddr);
$rserve_proto = getprotobyname('tcp');

unless ( socket(SOCK, PF_INET, SOCK_STREAM, $rserve_proto) &&
	connect(SOCK, $rserve_paddr) ) 
{
    print STDERR "Could not establish connection to $CONFIG_DEFAULTS{'RSERVE_HOST'}\n";
    print STDERR "on port $CONFIG_DEFAULTS{'RSERVE_PORT'}, the address you provided\n";
    print STDERR "for your R server.\n";
    print STDERR "DVN can function without a working R server, but\n";
    print STDERR "much of the functionality concerning running statistics\n";
    print STDERR "and analysis on quantitative data will not be available.\n";
    print STDERR "Please consult the \"Installing R\" section in the Installers guide\n";
    print STDERR "for more info.\n";

    exit 0;
    
}

close (SOCK); 
print "\nOK!\n";
}
exit 0; 


sub create_pg_hash {
    local $pg_username = shift @_; 
    local $pg_password = shift @_; 

    $encode_line = $pg_password . $pg_username; 

    # for Redhat: 

    ##print STDERR "executing /bin/echo -n $encode_line | md5sum\n"; 

    if ( $WORKING_OS eq "MacOSX" )
    {
	$hash = `/bin/echo -n $encode_line | md5`; 
    }
    else 
    {
	$hash = `/bin/echo -n $encode_line | md5sum`; 
    }

    chop $hash; 

    $hash =~s/  \-$//; 

    if ( (length($hash) != 32) || ($hash !~ /^[0-9a-f]*$/) ) 
    {
	print STDERR "Failed to generate a MD5-encrypted password hash for the Postgres database.\n";
	exit 1; 
    }


    return $hash;
}
