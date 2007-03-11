#!/usr/local/bin/perl5 -w

################################################################################
## EZemail is a small email program that demonstrates some of Perl's TK, POP/SMTP
## & MIME capabilities. EZemail requires perl, TK, LibNet(Net::SMTP & Net::POP3)
## and MIME:Lite to be installed on your system. This program is released under
## the "Artistic License", if you find it useful, helpful or improve it let me
## know by testing it out and sending me an email.  Send to: ikepgh@yahoo.com
##
## ikepgh - 12/17/04
##
## Disclaimer:  This program comes with no warranty!!  Use at your own risk!!
################################################################################

use Tk;
use strict;
use Tk::Dialog;
use Tk::ROText;
use Tk::Balloon;
use Net::SMTP;  # send messages
use Net::POP3;  # receive messages
use MIME::Lite; # send attachments
use Time::localtime; # timestamp
use Socket;  # IP routine
use Sys::Hostname;  # IP routine
use Tk::DialogBox;  # config settings
use Tk::NoteBook;  # config settings
use Tk::LabEntry;  # config settings
use Data::Dumper;  # config settings

###### DEFAULT CONFIG: (IF 'settings.cfg' DOES NOT EXIST) ######
my $config = {SMTP_SERVER => 'smtp.yourserver.com',
              POP_SERVER  => 'pop.yourserver.com',
              USER_NAME   => 'username',
              PASSWORD    => 'password',
              EMAIL       => 'username@yourserver.com'};
               
###### READ CONFIGURATION ######
readConfig("settings.cfg");

###### LOAD CONFIGURATION VARIABLES ######
my $Smtp     = $config -> {SMTP_SERVER};
my $Pop      = $config -> {POP_SERVER};
my $UserName = $config -> {USER_NAME};
my $Password = $config -> {PASSWORD};
my $Email    = $config -> {EMAIL};

###### GLOBAL VARIABLE DECLARATIONS ######
my ($tomail, $ccmail, $bccmail, $subjectmail, $attachment);

###### MAIN WINDOW ######
my $Version = "2.1";
my $main = MainWindow -> new();
$main -> title("EZemail $Version");
$main -> minsize( qw(350 300));
$main -> maxsize( qw(350 300));

###### CENTER MAIN WINDOW ######
my $x = int(($main -> screenwidth  / 2) - (175)); # half the width
my $y = int(($main -> screenheight / 2) - (175)); # half the height
$main -> geometry(350 . "x" . 350 . "+" . $x . "+" . $y); # window size

###### MENU ITEMS ######
my $menu = $main -> Frame(-background => 'blue')
                          -> pack('-side' => 'top', -fill => 'x');

my $file = $menu -> Menubutton(-text => 'File',
                               -background => 'blue', -foreground => 'white',
                               -activebackground => 'blue', -activeforeground => 'grey',
                               -tearoff => 0)
                               -> pack(-side => 'left');

   $file -> command(-label => 'Exit',
                    -background => 'blue', -foreground => 'white',
                    -activebackground => 'blue', -activeforeground => 'grey',
                    -command => sub {$main -> destroy});

my $edit = $menu -> Menubutton(-text => 'Settings',
                               -background => 'blue', -foreground => 'white',
                               -activebackground => 'blue', -activeforeground => 'grey',
                               -tearoff => 0)
                               -> pack(-side => 'left');

   $edit -> command(-label => 'Configure',
                    -background => 'blue', -foreground => 'white',
                    -activebackground => 'blue', -activeforeground => 'grey',
                    -command => \&doConfig);
                    
my $misc = $menu -> Menubutton(-text => 'Misc',
                               -background => 'blue', -foreground => 'white',
                               -activebackground => 'blue', -activeforeground => 'grey',
                               -tearoff => 0)
                               -> pack(-side => 'left');

   $misc -> command(-label => 'IP Check',
                    -background => 'blue', -foreground => 'white',
                    -activebackground => 'blue', -activeforeground => 'grey',
                    -command => \&getIP);

my $help = $menu -> Menubutton(-text => 'Help',
                               -background => 'blue', -foreground => 'white',
                               -activebackground => 'blue', -activeforeground => 'grey',
                               -tearoff => 0)
                               -> pack(-side => 'left');

   $help -> command(-label => 'Help',
                    -background => 'blue', -foreground => 'white',
                    -activebackground => 'blue', -activeforeground => 'grey',
                    -command => sub {getHelp()});

   $help -> separator();

   $help -> command(-label => 'About',
                    -background => 'blue', -foreground => 'white',
                    -activebackground => 'blue', -activeforeground => 'grey',
                    -command => \&about);

###### IMAGE AND TO WIDGETS ######
my $frame1 = $main -> Frame(-relief => 'groove',
                            -borderwidth => 0, -background => 'blue')
                            -> pack(-side => 'top', -fill => 'x');

my $photo = $frame1 -> Photo('imggif', -file => "email.gif");

my $label = $frame1 -> Label('-image' => 'imggif', -background => 'blue')
                              -> pack(-side => 'left');
                          
my $label1 = $frame1 -> Label(-text => 'To:',
                              -background => 'blue', -foreground => 'white')
                              -> pack(-side => 'left', -fill => 'x');
                              
my $balloon1 = $label1 -> Balloon(-background => 'grey');

   $balloon1 -> attach($label1, -balloonmsg => "Separate multiple email addresses with a comma
for example:  a\@b.com, c\@d.net, d\@e.org");

my $entry1 = $frame1 -> Entry(-textvariable => \$tomail,
                              -width => 48, -background => 'white',
                              -bd => "3", -relief => "sunken")
                              -> pack(-side => 'left', -fill => 'x', -pady => 0);
                              
###### CC WIDGETS ######
my $frame2 = $main -> Frame(-relief => 'groove',
                            -borderwidth => 1, -background => 'blue')
                            -> pack(-side => 'top', -fill => 'x');

my $label2 = $frame2 -> Label(-text => '         Cc:',
                              -background => 'blue', -foreground => 'white')
                              -> pack(-side => 'left');

my $balloon2 = $label2 -> Balloon(-background => 'grey');

   $balloon2 -> attach($label2, -balloonmsg => "Separate multiple email addresses with a comma
for example:  a\@b.com, c\@d.net, d\@e.org");
                              
my $entry2 = $frame2 -> Entry(-textvariable => \$ccmail,
                              -width => 48, -background => 'white',
                              -bd => "3", -relief => "sunken")
                              -> pack(-side => 'left', -fill => 'x', -pady => 1);
                              
###### BCC WIDGETS ######
my $frame3 = $main -> Frame(-relief => 'groove',
                            -borderwidth => 1, -background => 'blue')
                            -> pack(-side => 'top', -fill => 'x');

my $label3 = $frame3 -> Label(-text => '       Bcc:',
                              -background => 'blue', -foreground => 'white')
                              -> pack(-side => 'left');

my $balloon3 = $label3 -> Balloon(-background => 'grey');

   $balloon3 -> attach($label3, -balloonmsg => "Separate multiple email addresses with a comma
for example:  a\@b.com, c\@d.net, d\@e.org");

my $entry3 = $frame3 -> Entry(-textvariable => \$bccmail,
                              -width => 48, -background => 'white',
                              -bd => "3", -relief => "sunken")
                              -> pack(-side => 'left', -fill => 'x', -pady => 1);

###### ATTACHMENT WIDGETS ######
my $frame4 = $main -> Frame(-relief => 'groove',
                            -borderwidth => 1, -background => 'blue')
                            -> pack(-side => 'top', -fill => 'x');

my $label4 = $frame4 -> Label(-text => '   Attach:',
                              -background => 'blue', -foreground => 'white')
                              -> pack(-side => 'left');

my $entry4 = $frame4 -> Entry(-textvariable => \$attachment,
                              -width => 48, -background => 'white',
                              -bd => "3", -relief => "sunken")
                              -> pack(-side => 'left', -fill => 'x', -pady => 1);

my $balloon4 = $label4 -> Balloon(-background => 'grey');

   $balloon4 -> attach($label4, -balloonmsg => "Type in the full path to add an attachment
for example:  c:/ezemail/email.gif");
                              
###### SUBJECT WIDGETS ######
my $frame5 = $main -> Frame(-relief => 'groove',
                            -borderwidth => 0, -background => 'blue')
                            -> pack(-side => 'top', -fill => 'x');

my $label5 = $frame5 -> Label(-text => '  Subject:',
                              -background => 'blue', -foreground => 'white')
                              -> pack(-side => 'left');

my $entry5 = $frame5 -> Entry(-textvariable => \$subjectmail,
                              -width => 48, -background => 'white',
                              -bd => "3", -relief => "sunken")
                              -> pack(-side => 'left', -fill => 'x', -pady => 1);

my $balloon5 = $label5 -> Balloon(-background => 'grey');

   $balloon5 -> attach($label5, -balloonmsg => "Enter a Subject");
                              
###### MESSAGE WIDGETS ######
my $frame6 = $main -> Frame(-relief => 'groove',
                            -borderwidth => 3, -background => 'blue')
                            -> pack(-side => 'top', -fill => 'y');

my $text1 = $frame6 -> Text(-wrap => 'word',
                            -width => 50, -height => 7,
                            -background => 'white');

my $textscroll = $frame6 -> Scrollbar(-command => ['yview', $text1]);
   $text1 -> configure(-yscrollcommand => ['set', $textscroll]);
   $textscroll -> pack(-side => 'right', -fill => 'y');
   $text1 -> pack();

###### BUTTON WIDGETS ######
my $frame7 = $main -> Frame(-relief => 'groove',
                            -borderwidth => 4, -background => 'blue',)
                            -> pack(-side => 'top', -fill => 'x');

my $clear = $frame7 -> Button(-text => 'Clear', -background => 'grey',
                              -activebackground => 'grey', -activeforeground => 'blue',
                              -width => 11, -command => sub {$entry1 -> delete(0, 'end');
                                                             $entry2 -> delete(0, 'end');
                                                             $entry3 -> delete(0, 'end');
                                                             $entry4 -> delete(0, 'end');
                                                             $entry5 -> delete(0, 'end');
                                                             $text1  -> delete('1.0', 'end');})
                              -> pack(-side => 'left');
                            
my $check = $frame7 -> Button(-text => 'POP Check', -background => 'grey',
                              -activebackground => 'grey', -activeforeground => 'blue',
                              -width => 14, -command => sub {doPopcheck()})
                              -> pack(-side => 'left');
                            
my $getButton = $frame7 -> Button(-text => 'View Message(s)', -background => 'grey',
                                  -activebackground => 'grey', -activeforeground => 'blue',
                                  -width => 15, -command => sub {getMessage()})
                                  -> pack(-side => 'left');
                                  
my $send = $frame7 -> Button (-text => 'Send', -background => 'grey',
                              -activebackground => 'grey', -activeforeground => 'blue',
                              -width => 11, -command => sub {doSmtp($tomail, $subjectmail, $text1)})
                              -> pack(-side => 'left');
                            
###### START OF PROGRAM ######
MainLoop();

###### SEND EMAIL SUBROUTINE ######
sub doSmtp {

    # Very Simple Error Checking
    if (length($subjectmail) < 1 ) {
        &throwError;
    return 0;
    }

    my $text2 = @_;
    my @bodymail = $text1 -> get('1.0', 'end');
    
    my $now = ctime(); # Create a timestamp

    my $msg = MIME::Lite -> new (
               Date      => $now,
               From      => $Email,
               To        => $tomail,
               Cc        => $ccmail,
               Bcc       => $bccmail,
               Subject   => $subjectmail,
               Data      => @bodymail );
               
    # Very, Very Simple Error Checking
    if (length($attachment) > 1 ) {

       $msg -> attach (
               Type    => 'Auto',
               Path    => $attachment,
               ReadNow => 1 );
    }

       $msg -> scrub(); # Suppress Content headers

    # Open the connection
    my $smtp = Net::SMTP -> new($Smtp, Debug => 0) or die "Can't connect to SMTP host $Smtp\n";
    # Read the addresses
    $smtp -> mail($Email);
    my @toit = split  ',' , $tomail;
    $smtp -> to(@toit);
    my @ccit = split  ',' , $ccmail;
    $smtp -> cc(@ccit);
    my @bccit = split  ',' , $bccmail;
    $smtp -> bcc(@bccit);

    $smtp -> data(); # Start the email
    $smtp -> datasend($msg -> as_string);
    $smtp -> dataend(); # Finish sending the email
    $smtp -> quit; # Close the connection
    
    # Message sent dialog
    my $dialogmsg1 = $main -> Dialog(-title => 'EZemail - Message Sent',
                                     -text => "Your message was sent:\n $now",
                                     -default_button => 'OK',
                                     -bitmap => 'info') -> Show();
    return 0;
}

###### POPCHECK SUBROUTINE ######
sub doPopcheck {

    # Open the connection
    my $pop3 = Net::POP3 -> new($Pop);
    my $New_Messages = $pop3 -> login($UserName, $Password);

    if ($New_Messages > 0) {

    my $dialogmsg2 = $main -> Dialog(-title => 'EZemail - New Messages',
                                     -text => "$New_Messages New Message(s)",
                                     -default_button => 'OK',
                                     -bitmap => 'info') -> Show();
    }
    else {

    my $dialogmsg2 = $main -> Dialog(-title => 'EZemail - No New Messages',
                                     -text => 'No New Messages',
                                     -default_button => 'OK',
                                     -bitmap => 'info') -> Show();
        return 0;
    }
}

###### VIEW EMAIL SUBROUTINE ######
sub getMessage {

    my $pop3 = Net::POP3 -> new($Pop);
    my $Num_Messages = $pop3 -> login($UserName, $Password);
    my ($Messages, $message_id);

    $Messages = $pop3 -> list();

        if ($Num_Messages == 0) {

            my $dialogmsg3 = $main -> Dialog(-title => 'EZemail - No New Messages',
                                             -text => 'No New Messages',
                                             -default_button => 'OK',
                                             -bitmap => 'info') -> Show();
        }

        foreach $message_id (keys(%$Messages)) {

            $Messages = $pop3 -> get($message_id);
            # Display messages
            my $main = MainWindow -> new();
            # Display the message with the Helvetica font familiy
            my $font = $main -> fontCreate(-family => 'Helvetica', -size => 10);

            my $text2 = $main -> Text(-wrap => 'word', -relief => 'raised',
                                      -padx => '15', -pady => '15',
                                      -borderwidth => 15, -font => $font);

            my $scroll2 = $main -> Scrollbar(-command => ['yview', $text2]);
               $scroll2 -> pack(-side => 'right', -fill => 'y');
               $text2 -> configure(-yscrollcommand => ['set', $scroll2]);
               $text2 -> insert('1.0', "@$Messages");
               $text2 -> pack(-side => 'left', -fill => 'both', -expand => 1);

            # Displays one message at a time: NEXT CLOSE OR DELETE
            my $dialogmsg4 = $main -> Dialog(-title => 'EZemail - View Message',
                                             -text => "Please Select An Option",
                                             -default_button => 'Next',  -buttons => ['Next', 'Close', 'Delete'],
                                             -bitmap => 'question') -> Show();

            if ($dialogmsg4 eq 'Delete' ) {

                $pop3 -> delete($message_id);
                $main -> destroy if Tk::Exists($main);
            }

            if ($dialogmsg4 eq 'Close') {

                $main -> destroy if Tk::Exists($main);
            }

        next;
        }
    # Finish loop and close connection
    $pop3 -> quit();
}

###### CHECK IP SUBROUTINE ######
sub getIP {

    my $host = hostname();
    my $addr = inet_ntoa((gethostbyname($host))[4]);
    # Display it
    my $dialogmsg5 = $main -> Dialog(-title => 'EZemail - IP Address',
                                     -text => "IP Address: $addr\n Computer Name: $host",
                                     -default_button => 'OK',
                                     -bitmap => 'info') -> Show();
}

###### ABOUT SUBROUTINE ######
sub about {

    my $dialogmsg6 = $main -> Dialog(-title => 'EZemail - About',
                                     -text => "EZemail $Version  (2001 - 2004)\n Distributed under the Artistic License\n -- thanks ikepgh\@yahoo.com ",
                                     -default_button => 'OK',
                                     -bitmap => 'info') -> Show();
}

###### HELP SUBROUTINE ######
sub getHelp {

    my $main = MainWindow -> new();
            
    $main -> title("EZemail Help $Version");
    $main -> minsize( qw(650 250));
    $main -> maxsize( qw(650 250));

###### CENTER ######
    my $x = int(($main -> screenwidth  / 2) - (325)); # half the width
    my $y = int(($main -> screenheight / 2) - (125)); # half the height
    $main -> geometry(650 . "x" . 250 . "+" . $x . "+" . $y); # window size
    
#Read Only Text
    my $text2 = $main -> ROText(-wrap => 'word', -borderwidth => '5',
                                -relief => 'sunken', -background => 'blue',
                                -foreground => 'white');
     # Scroll Bar Currently Commented Out
#    my $tscroll2 = $main -> Scrollbar(-command => ['yview', $text2]);
#    $text2 -> configure(-yscrollcommand => ['set', $tscroll2]);
     $text2 -> pack(-side => 'left', -fill => 'both', -expand => 1);
#    $tscroll2 -> pack(-side => 'left', -fill => 'y');
     $text2 -> insert('1.0',
"EZemail $Version -- Welcome to the Help Section!   http://sourceforge.net/projects/ezemail/\n
Common Problems:
1. Have you installed on your system the following Perl packages: Tk, LibNet, Mime::Lite?
2. Ensure that 'email.gif' is in the same directory as EZemail or the program won't load
3. Make sure your username, password, email and SMTP/POP servers are entered correctly
4. Ensure that 'settings.cfg' is in the same directory as EZemail or it won't be read...
   You must first save your configuration settings, in order for this file to be created!

Known Bugs, To Do, Planned Features, Etc...:
1. Parsing of MIME attachments needs implemented; Currently only sends one attachment.
2. No Reply, Forward or Printing capability yet
3. No Inbox, Outbox, Sentbox capability yet
4. More features are added as I learn more Perl/Tk...

Other Questions?  Feel free to email me: ikepgh\@yahoo.com
Credits: Thanks rowleyp and zentara for the assistance!!");
}

###### ERROR CHECKING SUBROUTINE ######
sub throwError {
    my $dialogmsg7 = $main -> Dialog(-title => 'EZemail - Subject Line Error',
                                     -text => 'You must enter a subject!',
                                     -default_button => 'OK',
                                     -bitmap => 'error') -> Show();
}

###### READ CONFIG SUBROUTINE ######
sub readConfig {
    my $file = shift;
    my $VAR1;

    local ($/);
    undef $/;

    return unless $file;
    return unless -e $file;

    open IN, $file;
    my $textfile  = <IN>;
    close (IN);

    $config = eval $textfile;
}

###### DO CONFIG SUBROUTINE ######
sub doConfig {

    my $localconfig;

        foreach (keys %$config) {
        $localconfig -> {$_} = $config -> {$_};
        }

     my $dialogmsg8 = $main -> DialogBox(-title => "EZemail $Version Configuration",
			                                   -buttons => ["Save", "Cancel"]);

	   my $notebook = $dialogmsg8 -> add('NoteBook', -ipadx => 6, -ipady => 6);
     my $usertab = $notebook -> add("userid", -label => "User");
     my $servertab = $notebook -> add("server",  -label => "Servers");

	      $usertab -> LabEntry(-background => "white", -bd => "3", -relief => "sunken", -label => "User Name:              ",
	                           -labelPack => [-side => "left", -anchor => "w"],
                             -width => 30, -textvariable => \$localconfig -> {USER_NAME})
                             -> pack(-side => "top", -anchor => "e");

        $usertab -> LabEntry(-background => "white", -bd => "3", -relief => "sunken",
                             -label => "Password:                ",
                             -labelPack => [-side => "left", -anchor => "w"], -width => 30,
                             -textvariable => \$localconfig -> {PASSWORD}, -show => '*')
                             -> pack(-side => "top", -anchor => "e");

        $usertab -> LabEntry(-background => "white", -bd => "3", -relief => "sunken",
                             -label => "Email Address:          ",
                             -labelPack => [-side => "left", -anchor => "w"], -width => 30,
                             -textvariable => \$localconfig -> {EMAIL})
                             -> pack(-side => "top", -anchor => "e");

	      $servertab -> LabEntry(-background => "white", -bd => "3", -relief => "sunken",
                               -label => "SMTP Server:           ",
	                             -labelPack => [-side => "left", -anchor => "w"], -width => 30,
                               -textvariable => \$localconfig -> {SMTP_SERVER})
                               -> pack(-side => "top", -anchor => "e");

	      $servertab -> LabEntry(-background => "white", -bd => "3", -relief => "sunken",
                               -label => "POP Server:              ",
	                             -labelPack => [-side => "left", -anchor => "w"], -width => 30,
                               -textvariable => \$localconfig -> {POP_SERVER})
                               -> pack(-side => "top", -anchor => "e");

        $notebook -> pack(-expand => "yes", -fill => "both",
                          -padx => 5, -pady => 5, -side => "top");
                          
        my $result = $dialogmsg8 -> Show;

     #Save Configuration
     if ($result =~ /Save/) {

        foreach (keys %$config) {
            $config -> {$_} = $localconfig -> {$_};
        }

        my @types = (["Config Files", '.cfg', 'TEXT'], ["All Files", "*"]);

        my $file = $main -> getSaveFile(-filetypes => \@types,
				                                -initialfile => 'settings',
                                        -defaultextension => '.cfg');

        open  OUT, ">$file";
        print OUT Dumper $config;
        close (OUT);

        my $dialogmsg9 = $main -> Dialog(-title => 'EZemail - Restart?',
                                         -text => "Any changes to your settings requires EZemail $Version to be restarted in order to take effect...",
                                         -default_button => 'OK',
                                         -bitmap => 'info') -> Show();
     }
}
