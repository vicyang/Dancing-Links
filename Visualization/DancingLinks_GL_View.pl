=info
    DancingLinks 求解精确覆盖问题 Perl 实现
    523066680 2017-09
    https://zhuanlan.zhihu.com/PerlExample
=cut

use strict;
#use warnings; # Can't locate package GLUquadricObjPtr for @OpenGL::Quad::ISA 
use feature 'state';
use Clone 'clone';
use Time::HiRes qw/sleep/;
use OpenGL qw/ :all /;
use OpenGL::Config;
use RandMatrix;
use DancingLinks;
use Data::Dumper;
$Data::Dumper::Maxdepth = 2;
use threads;
use threads::shared;
STDOUT->autoflush(1);


BEGIN
{
    our $WinID;
    our $HEIGHT = 600;
    our $WIDTH  = 1000;
    our %color_table = (
           black  => [0.0, 0.0, 0.0],
           green  => [0.8, 1.0, 0.4],
           blue   => [0.5, 0.8, 1.0],
           voilet => [0.6, 0.4, 0.9], 
           orange => [1.0, 0.6, 0.0]
        );

    our $PT_SIZE = 16;
    our $PT_SPACE = int($PT_SIZE * 1.3);

    #our $C = [ map { {} } ( 0.. $mat_cols ) ];
}

our $mat = [
        [0,0,1,0,1,1,0],
        [1,0,0,1,0,0,1],
        [0,1,1,0,0,1,0],
        [1,0,0,1,0,0,0],
        [0,1,0,0,0,0,1],
        [0,0,0,1,1,0,1]
    ];
our $mat_rows = scalar( @$mat );
our $mat_cols = scalar( @{$mat->[0]} );

# our $mat;
# our $mat_rows = 20;
# our $mat_cols = 20;
# make_mat( \$mat, $mat_rows, $mat_cols );
DancingLinks::init( $mat, $mat_rows, $mat_cols  );

our $T1 :shared;
our $T2 :shared;
our @answer :shared; # = map { {} } (1..20);
our $C = clone( $DancingLinks::C );
our $SHARE :shared;
$SHARE = shared_clone( [ map { [map { 0 } (0..$mat_cols)] } (0..$mat_rows) ] );
clone_DLX( $C->[0], $SHARE );
#grep { printf "%s\n", join( "", @$_ ) } @$SHARE;

#exit;
$T1 = 0.05;
$T2 = 2.0;
DancingLinks::print_links( $C->[0] );
our $th = threads->create( \&dance, $C->[0], \@answer, 0 );
$th->detach();
main();

sub make_mat
{
    my ($ref, $rows, $cols) = @_;
    #srand(1); # dancing long time, rows=50 cols=20
    srand(1);
    $RandMatrix::n = 8;     #实际有效的行数
    $RandMatrix::m = $cols;
    RandMatrix::create_mat( $ref );
    RandMatrix::fill_rand_row( $$ref, $rows - $RandMatrix::n );
    #RandMatrix::dump_mat( $$ref );
    RandMatrix::show_answer_row();
}

DANCING:
{
    sub clone_DLX
    {
        our $SHARE;
        my ( $head, $ref )= @_;
        my $vt;
        my $hz;
        my $c = $head->{right};
        
        for ( ; $c != $head; $c = $c->{right} )
        {
            $SHARE->[0][ $c->{col} ] = "green";
            $vt = $c->{down};
            for ( ; $vt != $c; $vt = $vt->{down} )
            {
                $SHARE->[$vt->{row}][$vt->{col}] = "green";
            }
        }
    }

    sub dance
    {
        our $SHARE;
        my ($head, $answer, $lv) = @_;
        return 1 if ( $head->{right} == $head );

        my $c = $head->{right};
=opt
        my $min = $c;
        #get minimal column node
        while ( $c != $head )
        {
            if ( $c->{count} < $min->{count} ) { $min = $c; }
            $c = $c->{right};
        }
        $c = $min;
=cut
        return 0 if ( $c->{count} <= 0 );

        my $r = $c->{down};
        my $ele;

        my @count_array;
        my $res = 0;
        printf "Remove: %d\n", $c->{col};
        remove_col( $c, "blue" );
        sleep $T2;

        while ( $r != $c )
        {
            $ele = $r->{right};
            while ( $ele != $r )
            {
                printf "Remove: %d\n", $ele->{col};
                remove_col( $ele->{top}, "orange" );
                $ele = $ele->{right};
                sleep $T2;
            }

            # Clean 

            $res = dance($head, $answer, $lv+1);
            if ( $res == 1)
            {
                $answer->[$lv] = shared_clone($r);

                my $tc = $r;
                do {
                    $SHARE->[ $tc->{row} ][ $tc->{col} ] = "green";
                    $tc = $tc->{right};
                } until ( $tc == $r );

                return 1;
            }

            sleep 1.0;
            sleep $T1;
            $ele = $r->{left};
            while ( $ele != $r )
            {
                printf "Resume: %d\n", $ele->{col};
                resume_col( $ele->{top}, "green" );
                $ele = $ele->{left};
            }
         
            $r = $r->{down};
        }

        resume_col( $c, "green" );
        printf "Resume: %d\n", $c->{col};
        return $res;
    }

    sub remove_col
    {
        our $SHARE;
        my ( $sel, $color ) = @_;

        #printf "Remove: %d\n", $sel->{col};
        $SHARE->[ $sel->{row} ][ $sel->{col} ] = $color;
        sleep $T1;
        $sel->{left}{right} = $sel->{right};
        $sel->{right}{left} = $sel->{left};

        my $vt = $sel->{down};
        my $hz;

        for ( ; $vt != $sel; $vt = $vt->{down} )
        {
            $SHARE->[ $vt->{row} ][ $vt->{col} ] = $color;
            sleep $T1;
            $hz = $vt->{right};
            for (  ; $hz != $vt; $hz = $hz->{right})
            {
                $SHARE->[ $hz->{row} ][ $hz->{col} ] = $color;
                sleep $T1;
                $hz->{up}{down} = $hz->{down};
                $hz->{down}{up} = $hz->{up};
                $hz->{top}{count} --;
                #$SHARE->[ $hz->{row} ][ $hz->{col} ] = 0;
            }
            $hz->{top}{count} --;
        }

        #sleep $T1;
    }

    sub resume_col
    {
        my ( $sel, $color ) = @_;
        
        $sel->{left}{right} = $sel;
        $sel->{right}{left} = $sel;
        $SHARE->[ $sel->{row} ][ $sel->{col} ] = $color;
        sleep $T1;
        my $vt = $sel->{down};
        my $hz;

        for ( ; $vt != $sel; $vt = $vt->{down})
        {
            $hz = $vt->{right};
            $SHARE->[ $vt->{row} ][ $vt->{col} ] = $color;
            sleep $T1;
            for (  ; $hz != $vt; $hz = $hz->{right})
            {
                $SHARE->[ $hz->{row} ][ $hz->{col} ] = $color;
                sleep $T1;
                $hz->{up}{down} = $hz;
                $hz->{down}{up} = $hz;
                $hz->{top}{count} ++;
            }
            $hz->{top}{count} ++;
        }
    }
}

sub display
{
    our ($C, %color_table, $WinID, $SHARE, $PT_SIZE, $PT_SPACE);
    glColor3f(1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    #print_color_table();

    glBegin(GL_POINTS);
    for my $r ( 0 .. $mat_rows )
    {
        for my $c ( 0 .. $mat_cols )
        {
            if ( $SHARE->[$r][$c] ne 0 )
            {
                glColor3f( @{ $color_table{ $SHARE->[$r][$c] } } );
                glVertex3f( $c * $PT_SPACE, -$r * $PT_SPACE, 0.0 );
            }
        }
    }
    glEnd();

    glutSwapBuffers();
}

sub print_color_table
{
    our @color_table;
    my $pt_size = glGetFloatv_p(GL_POINT_SIZE);
    my $block = $pt_size + 5.0;
    my $y = 30.0;
    glColor3f( 0.5, 0.5, 0.5 );
    glRectf(-$block, $y - $block , scalar(@color_table)*$block, $y + $block );
    glBegin(GL_POINTS);
    for my $id ( 0 .. $#color_table )
    {
        glColor3f( @{$color_table[ $id ]} );
        glVertex3f( $id * $block, 30.0, 0.0 );
    }
    glEnd();
}


sub idle 
{
    our ($th);
    state $printed = 0;
    sleep 0.05;

    if ( ! $th->is_running() and $printed == 0  )
    {
        $printed = 1;
        printf "Result: %s\n", join(",", map { $_->{row} } @answer);
    }
    
    glutPostRedisplay();
}

sub init
{
    our $PT_SIZE;
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glPointSize( $PT_SIZE );
}

sub reshape
{
    my ($w, $h) = (shift, shift);
    state $vthalf = $w/2.0;
    state $hzhalf = $h/2.0;
    state $fa = 100.0;

    glViewport(0, 0, $w, $h);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-100, $w-100, -($h-100), 100, 0.0, $fa*2.0); 
    #glFrustum(-100.0, $WIDTH-100.0, -100.0, $HEIGHT-100.0, 800.0, $fa*5.0); 
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    gluLookAt(0.0,0.0,$fa, 0.0,0.0,0.0, 0.0,1.0, $fa);
}

sub hitkey
{
    our $WinID;
    my $k = lc(chr(shift));
    if ( $k eq 'q') { quit() }
}

sub quit
{
    our $WinID;
    glutDestroyWindow( $WinID );
    exit 0;
}

sub main
{
    our ($MAIN, $WIDTH, $HEIGHT, $WinID);

    glutInit();
    glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE );
    glutInitWindowSize($WIDTH, $HEIGHT);
    glutInitWindowPosition(100, 100);
    $WinID = glutCreateWindow("Show");
    
    &init();
    glutDisplayFunc(\&display);
    glutReshapeFunc(\&reshape);
    glutKeyboardFunc(\&hitkey);
    glutIdleFunc(\&idle);
    glutMainLoop();
}
