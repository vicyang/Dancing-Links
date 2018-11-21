=info
    DancingLinks 求解精确覆盖问题 Perl 实现
    523066680 2017-09
    https://zhuanlan.zhihu.com/PerlExample
=cut

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
use ImagerFont;
use FontCanvas;
STDOUT->autoflush(1);

BEGIN
{
    our $WinID;
    our $HEIGHT = 600;
    our $WIDTH  = 1000;
    our %color_table = (
           black  => [0.0, 0.0, 0.0],
           green  => [0.5, 0.8, 0.2],
           blue   => [0.5, 0.8, 1.0],
           voilet => [0.6, 0.4, 0.9], 
           orange => [1.0, 0.6, 0.0],
           Turquoise => [0.7, 0.9, 0.9],
           AntiqueWhite => [1.0, 0.9, 0.8],
           beige => [1.0, 1.0, 0.9],
           gray => [0.3, 0.3, 0.3],
        );

    our $PT_SIZE = 30;
    our $PT_SPACE = int($PT_SIZE * 1.3);
    our $PAUSE = 0;

    #our $C = [ map { {} } ( 0.. $mat_cols ) ];
}

INIT
{
    our ($PT_SIZE);
    $ImagerFont::SIZE = $PT_SIZE*0.5;
    $ImagerFont::w = $PT_SIZE;
    $ImagerFont::h = $PT_SIZE;

    # 创建标签字符模板
    our @TEXT = map { ("C$_", "R$_") } ( 0 .. 20 );
    our %TEXT_DATA;

    for my $s ( @TEXT )
    {
        $TEXT_DATA{$s} = {};
        ImagerFont::get_text_map( $s , $TEXT_DATA{$s} );
        #printf "%d %d\n", $TEXT_DATA{$s}->{h}, $TEXT_DATA{$s}->{w};
    }

    # 字幕画布
    our $canvas;
    our $cv_str :shared;
    $cv_str = "";
    $canvas = {'w'=>undef, 'h'=>undef, 'array'=>undef };

    $FontCanvas::SIZE = 18;
    $FontCanvas::h = $HEIGHT - 200;
    $FontCanvas::w = $WIDTH * 0.5;
    FontCanvas::init( $canvas );
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

# $mat_rows = 12;
# $mat_cols = 10;
# make_mat( \$mat, $mat_rows, $mat_cols );
DancingLinks::init( $mat, $mat_rows, $mat_cols  );

our $T1 :shared;
our $T2 :shared;
our @answer :shared; # = map { {} } (1..20);
our $C = clone( $DancingLinks::C );
our $SHARE :shared;

# 两种延时间隔
$T1 = 0.2;
$T2 = 0.6;

# 用于展示的矩阵，初始化为 undef
$SHARE = shared_clone( [ map { [map { undef } (0..$mat_cols)] } (0..$mat_rows) ] );
# DLX 克隆到共享矩阵 
clone_DLX( $C->[0], $SHARE );

# 打印 链表 初始状态
DancingLinks::print_links( $C->[0] );

# 创建线程
our $th = threads->create( \&dance, $C->[0], \@answer, 0 );
$th->detach();
main();

sub make_mat
{
    my ($ref, $rows, $cols) = @_;
    #srand(1); # dancing long time, rows=50 cols=20
    srand(2);
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

    sub clean_color
    {
        our ($SHARE, $mat_rows, $mat_cols);
        for my $r ( 0 .. $mat_rows ) {
            for my $c ( 0 .. $mat_cols ) {
                if ( defined $SHARE->[$r][$c] and $SHARE->[$r][$c] ne 'green' ) {
                    $SHARE->[$r][$c] = "gray";
                }
            }
        }
    }

    sub dance
    {
        our ($SHARE, $canvas, $cv_str);
        my ($head, $answer, $lv) = @_;
        return 1 if ( $head->{right} == $head );

        my $c = $head->{right};

        # # 优化算法，选择下方重合元素最少的列（为了演示，暂时关闭优化）
        # my $min = $c;
        # #get minimal column node
        # while ( $c != $head )
        # {
        #     if ( $c->{count} < $min->{count} ) { $min = $c; }
        #     $c = $c->{right};
        # }
        # $c = $min;

        return 0 if ( $c->{count} <= 0 );

        my $r = $c->{down};
        my $ele;

        my @count_array;
        my $res = 0;
        remove_col( $c, "blue" );
        sleep $T2;

        # Code for Analyse #
        my $tmpr = $c->{down};
        my @possible_row;
        while ( $tmpr != $c )
        {
            push @possible_row, $tmpr->{row};
            $tmpr = $tmpr->{down};
        }
        # ---------------- #

        while ( $r != $c )
        {
            $cv_str = sprintf "%sPossible Rows: (%s), try row: %d", 
                               "    "x$lv, join(",", @possible_row), $r->{row};
            printf "%s\n", $cv_str;

            $ele = $r->{right};
            while ( $ele != $r )
            {
                remove_col( $ele->{top}, "orange" );
                $ele = $ele->{right};
            }

            # 清理已经处理过的单元
            sleep $T2;
            clean_color();  
            sleep $T2;

            $res = dance($head, $answer, $lv+1);
            if ( $res == 1)
            {
                $answer->[$lv] = shared_clone($r);
                return 1;
            }

            # Code for Analyse #
            else {
                $cv_str = sprintf "%sExclude Row: %d", "    "x$lv, $r->{row};
                printf "%s\n", $cv_str;
            }
            # ---------------- #

            sleep $T1;
            $ele = $r->{left};
            while ( $ele != $r )
            {
                resume_col( $ele->{top}, "green" );
                $ele = $ele->{left};
            }
         
            $r = $r->{down};
        }

        resume_col( $c, "green" );
        return $res;
    }

    sub remove_col
    {
        our $SHARE;
        my ( $sel, $color ) = @_;

        $SHARE->[ $sel->{row} ][ $sel->{col} ] = "voilet";
        sleep $T1;
        $sel->{left}{right} = $sel->{right};
        $sel->{right}{left} = $sel->{left};

        my $vt = $sel->{down};
        my $hz;

        for ( ; $vt != $sel; $vt = $vt->{down} )
        {
            printf "Remove: %d\n", $vt->{row};
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
            printf "Resume: %d\n", $vt->{row};
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
    our ($C, %color_table, $WinID, $SHARE, $PT_SIZE, $PT_SPACE, %TEXT_DATA);
    our ($canvas);

    glColor3f(1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    #print_color_table();
    glBegin(GL_POINTS);
    for my $r ( 0 .. $mat_rows )
    {
        for my $c ( 0 .. $mat_cols )
        {
            if ( defined $SHARE->[$r][$c] )
            {
                glColor3f( @{ $color_table{ $SHARE->[$r][$c] } } );
                glVertex3f( $c * $PT_SPACE, -$r * $PT_SPACE, 0.0 );
            }
        }
    }
    glEnd();

    # 列标编号
    for my $c ( 0 .. $mat_cols )
    {
        next if $SHARE->[0][$c] eq 'black';
        my $ref = $TEXT_DATA{ "C$c" };
        glRasterPos3f( $c * $PT_SPACE - $PT_SIZE/2.0, -$PT_SIZE/2.0, 0.0 );
        glDrawPixels_c( $ref->{w}, $ref->{h}, GL_RGBA, GL_UNSIGNED_BYTE, $ref->{array}->ptr() );
    }
    
    # 行编号
    for my $r ( 1 .. $mat_rows )
    {
        my $ref = $TEXT_DATA{"R$r"};
        glRasterPos3f( -$PT_SIZE/2.0 , -($r * $PT_SPACE + $PT_SIZE/2.0), 0.0 );
        glDrawPixels_c( $ref->{w}, $ref->{h}, GL_RGBA, GL_UNSIGNED_BYTE, $ref->{array}->ptr() );
    }

    # 字幕
    glRasterPos3f( 320.0,-380.0, 0.0 );
    glDrawPixels_c( $canvas->{w}, $canvas->{h}, GL_RGBA, GL_UNSIGNED_BYTE, $canvas->{array}->ptr() );

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
    our ($th, $cv_str);
    state $printed = 0;
    sleep 0.05;

    # 显示答案
    if ( ! $th->is_running() and $printed == 0  )
    {
        $printed = 1;
        $cv_str = sprintf "Result: %s", join(",", map { $_->{row} } @answer);
        printf "%s\n", $cv_str;

        # 更新矩阵显示
        my %answer = map { ($_->{row}, 1) } @answer;
        our ($SHARE, $mat_rows, $mat_cols);
        for my $r ( 0 .. $mat_rows ) {
            for my $c ( 0 .. $mat_cols ) {
                if ( defined $SHARE->[$r][$c] ) {
                    if ( exists $answer{$r} ) { $SHARE->[$r][$c] = "beige" }
                    else { $SHARE->[$r][$c] = "green" }
                }
            }
        }
    }
    
    # 更新画布显示文字
    if ($cv_str ne "")
    {
        FontCanvas::update_text( $cv_str , $canvas);
        $cv_str = "";
    }

    glutPostRedisplay();
}

sub init
{
    our $PT_SIZE;
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glPointSize( $PT_SIZE );
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
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
    our ($WinID, $T1, $T2, $PAUSE);
    my $k = lc(chr(shift));
    if ( $k eq 'q') { quit() }
    if ( $k eq 'p') { 
        $PAUSE = ! $PAUSE;
        #if ($PAUSE) { }
    }
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
