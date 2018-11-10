=info
    523066680/vicyang
    2018
=cut

#use strict;
use warnings;
use Data::Dump qw/dump/;
STDOUT->autoflush(1);

my $index = 0;
our $ele_id;
our @nodes;
our $mat = [
        [0,0,1,0,1,1,0],
        [1,0,0,1,0,0,1],
        [0,1,1,0,0,1,0],
        [1,0,0,1,0,0,0],
        [0,1,0,0,0,0,1],
        [0,0,0,1,1,0,1]
    ];
our $mat_rows = scalar(@$mat);
our $mat_cols = scalar( @{$mat->[0]} );

main();

sub main
{
    my $C;
    my @answer;
    my $res;

    # 提前创建每个标签的结构体"空间"
    $C = [ map { {} } (0 .. $mat_cols ) ];
    $ele_id = 1;

    #初始化列首节点
    init_head_col( $C, $mat_cols );
    create_matrix_nodes( $mat, $C );

    print_links( $C->[0] );

    $res = dance( $C->[0] , \@answer, 0);
    #print_links( $C->[0] );

    printf "%s\n", join(",", map { $_->{row} } @answer);
    printf "result: %d\n", $res;

    # #清理内存
    # clean_matrix_nodes($C);
}

sub create_matrix_nodes
{
    my ($mat, $C ) = @_;
    for my $r ( 0 .. $mat_rows-1 )
    {
        elements_to_nodes( $C, $mat->[$r], $mat_cols, $r, 0, 0 );
    }   
}

sub elements_to_nodes
{
    my ($C, $eles, $cols, $matr, $matc, $n ) = @_;

    our $ele_id;
    my $first;
    my $ele;
    my $ref;
    my $prev = undef;
    my $col;
    my $i;

    for ( $i = 0; $i < $cols; $i++ )
    {
        $col = $i+1;
        if ( $eles->[$i] == 1 )
        {
            $ele = {
                val => $n,
                col => $matc,
                row => $matr + 1,  #在交叉链中的行位
                count => undef,
                left  => undef,
                right => undef,
                up    => $C->[$col]{up},
                down  => $C->[$col],
                top   => $C->[$col]
            };

            $nodes[ $ele_id-1 ] = $ele;
            if ( $C->[$col]{down} == $C->[$col] ) 
            {
                $C->[$col]{down} = $ele;
            }

            $C->[$col]{up}{down} = $ele;
            $C->[$col]{up}       = $ele;
            $C->[$col]{count}++;

            if ( defined $prev )
            {
                $prev->{right} = $ele;
                $ele->{left}   = $prev;
            }
            else
            {
                $first = $ele;
            }

            $prev = $ele;
            $ele_id ++;
        }

        $first->{left} = $ele;
        $ele->{right}  = $first;
    }
}

sub init_head_col
{
    my ($C, $len) = @_;
    my ($left, $right);

    for my $col ( 0 .. $len )
    {
        $left = $col == 0 ? $len : $col-1;
        $right = $col == $len ? 0 : $col+1;
        $C->[$col]{val}  = 0;
        $C->[$col]{row}  = 0;
        $C->[$col]{col}  = $col;
        $C->[$col]{count} = 0;
        $C->[$col]{left}  = $C->[$left];
        $C->[$col]{right} = $C->[$right];
        $C->[$col]{up}    = $C->[$col];
        $C->[$col]{down}  = $C->[$col];
        $C->[$col]{top}   = $C->[$col];
    }
}


# ============================================================
#                       Dancing Links 
# ============================================================

DANCING:
{
    sub dance
    {
        my ($head, $answer, $lv) = @_;

        return 1 if ( $head->{right} == $head );

        my $c = $head->{right};
        my $min = $c;

        #get minimal column node
        while ( $c != $head )
        {
            if ( $c->{count} < $min->{count} ) { $min = $c; }
            $c = $c->{right};
        }

        $c = $min;
        return 0 if ( $c->{count} <= 0 );

        my $r = $c->{down};
        my $ele;

        my @count_array;
        my $res = 0;

        remove_col( $c );

        while ( $r != $c )
        {
            $ele = $r->{right};

            while ( $ele != $r )
            {
                remove_col( $ele->{top} );
                $ele = $ele->{right}
            }

            $res = dance($head, $answer, $lv+1);
            if ( $res == 1)
            {
                $answer->[$lv] = $r;
                return 1;
            }

            $ele = $r->{left};
            while ( $ele != $r )
            {
                resume_col( $ele->{top} );
                $ele = $ele->{left}
            }
         
            $r = $r->{down};
        }

        resume_col( $c );
        return $res;
    }

    sub remove_col
    {
        my ( $sel ) = @_;

        $sel->{left}{right} = $sel->{right};
        $sel->{right}{left} = $sel->{left};

        my $vt = $sel->{down};
        my $hz;

        for ( ; $vt != $sel; $vt = $vt->{down} )
        {
            $hz = $vt->{right};
            for (  ; $hz != $vt; $hz = $hz->{right})
            {
                $hz->{up}{down} = $hz->{down};
                $hz->{down}{up} = $hz->{up};
                $hz->{top}{count} --;
            }
            $hz->{top}{count} --;
        }
    }

    sub resume_col
    {
        my ( $sel ) = @_;

        $sel->{left}{right} = $sel;
        $sel->{right}{left} = $sel;

        my $vt = $sel->{down};
        my $hz;

        for ( ; $vt != $sel; $vt = $vt->{down})
        {
            $hz = $vt->{right};
            for (  ; $hz != $vt; $hz = $hz->{right})
            {
                $hz->{up}{down} = $hz;
                $hz->{down}{up} = $hz;
                $hz->{top}{count} ++;
            }
            $hz->{top}{count} ++;
        }
    }
}

sub print_links
{
    my $head = shift;
    my $tmat = [];

    # rows 多一行列标
    grep { push @$tmat, [map { "   " } (1 .. $mat_cols)] } (0 .. $mat_rows);

    my $vt;
    my $hz;
    my $c = $head->{right};

    for ( ; $c != $head; $c = $c->{right} )
    {
        $tmat->[0][$c->{col}] = " C".$c->{col};

        $vt = $c->{down};
        for ( ; $vt != $c; $vt = $vt->{down} )
        {
            $tmat->[$vt->{row}][$c->{col}] = sprintf "%3d", $vt->{val};
        }
    }

    for my $e ( @$tmat )
    {
        print join("", @$e),"\n";
    }

    print "\n";
}

sub clean_matrix_nodes
{
    my ( $C ) = @_;
    grep { %$_ = () } @nodes;
    grep { %$_ = () } @$C;
    @nodes = ();
    @$C = ();
}
